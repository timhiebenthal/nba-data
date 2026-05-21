"""@bruin
name: load.box_scores
connection: nba_duckdb

materialization:
  type: table
  strategy: merge

columns:
  - name: GAME_ID
    type: varchar
    primary_key: true
  - name: PERSON_ID
    type: integer
    primary_key: true
@bruin"""

import json
import os
import time
import pandas as pd
from nba_api.stats.endpoints import leaguegamefinder, boxscoretraditionalv3

# Explicit schema: only these columns are kept in the output.
# Extra fields from future API changes are silently dropped.
EXPECTED_COLUMNS = [
    "GAME_ID", "TEAM_ID", "PERSON_ID", "PLAYER_NAME",
    "START_POSITION", "COMMENT", "MIN", "FGM", "FGA", "FG_PCT",
    "FG3M", "FG3A", "FG3_PCT", "FTM", "FTA", "FT_PCT",
    "OREB", "DREB", "REB", "AST", "STL", "BLK", "TOV", "PF", "PTS",
    "PLUS_MINUS",
]


def _parse_boxscore(data: dict) -> list[dict]:
    """Flatten the nested box score JSON into a flat list of player-game records.

    The NBA API returns a deeply nested structure:
        boxScoreTraditional
          ├── homeTeam
          │     ├── teamId
          │     └── players[]
          │           ├── personId, name, position
          │           └── statistics{}  ← all the actual stats
          └── awayTeam (same structure)

    This function walks both teams, merges player metadata into the stats dict,
    and attaches game-level identifiers (GAME_ID, TEAM_ID) so each record is
    independently queryable.
    """
    records = []
    game_id = data.get("gameId")

    for team_key in ("homeTeam", "awayTeam"):
        team = data.get(team_key, {})
        team_id = team.get("teamId")

        for player in team.get("players", []):
            stats = player.get("statistics", {})
            stats.update({
                "GAME_ID": game_id,
                "TEAM_ID": team_id,
                "PERSON_ID": player.get("personId"),
                "PLAYER_NAME": player.get("name"),
                "START_POSITION": player.get("startPosition"),
                "COMMENT": player.get("comment"),
            })
            records.append(stats)

    return records


def materialize() -> pd.DataFrame:
    """Fetch player-level box score stats for all games in the date range.

    The NBA API has no bulk box score endpoint — each game requires an
    individual HTTP call. We first get the list of game IDs from
    LeagueGameFinder, then iterate over them one by one with a 2.5s
    delay between calls to respect rate limits.
    """
    vars = json.loads(os.environ.get("BRUIN_VARS", "{}"))
    start_date = str(vars.get("start_date", "2025-10-01"))
    end_date = str(vars.get("end_date", "2025-10-07"))

    print(f"Fetching box scores for games from {start_date} to {end_date}...")

    # Fetch all games for the season, then filter client-side.
    # The API doesn't support date-range filtering on this endpoint.
    gamefinder = leaguegamefinder.LeagueGameFinder(
        season_nullable="2025-26",
        season_type_nullable="Regular Season",
        player_or_team_abbreviation="T",
    )

    df = gamefinder.get_data_frames()[0]
    if df.empty:
        print("No games found from API.")
        return pd.DataFrame()

    df["GAME_DATE"] = pd.to_datetime(df["GAME_DATE"]).dt.strftime("%Y-%m-%d")
    game_ids = df.query(
        f"GAME_DATE >= '{start_date}' and GAME_DATE <= '{end_date}'"
    )["GAME_ID"].unique().tolist()

    if not game_ids:
        print(f"No games found in date range {start_date} to {end_date}.")
        return pd.DataFrame()

    print(f"Found {len(game_ids)} games to fetch box scores for.")

    all_records = []
    for i, game_id in enumerate(game_ids, 1):
        print(f"Processing game {i}/{len(game_ids)}: {game_id}")

        try:
            boxscore = boxscoretraditionalv3.BoxScoreTraditionalV3(game_id=game_id)
            data = boxscore.get_dict().get("boxScoreTraditional")

            if data is None:
                print(f"  No data for game {game_id}")
                continue

            all_records.extend(_parse_boxscore(data))

            # Rate limit: the NBA API returns 429 if calls are too frequent.
            time.sleep(2.5)

        except Exception as e:
            print(f"  Error fetching game {game_id}: {e}")
            continue

    if not all_records:
        print("No box score data collected.")
        return pd.DataFrame()

    result = pd.DataFrame(all_records)

    # Keep only expected columns — protects against unexpected API changes
    # that might add or remove fields.
    available = [c for c in EXPECTED_COLUMNS if c in result.columns]
    result = result[available]

    # Coerce numeric columns: some stats arrive as strings ("0" or "--")
    # from the API. Convert them to proper numeric types, turning
    # unparseable values into NaN.
    numeric_cols = [c for c in available if c not in ("GAME_ID", "PLAYER_NAME", "START_POSITION", "COMMENT")]
    for col in numeric_cols:
        result[col] = pd.to_numeric(result[col], errors="coerce")

    print(f"Returning {len(result)} player-game records.")
    return result
