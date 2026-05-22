"""@bruin
name: raw.raw_box_scores
connection: nba_duckdb
@bruin"""

import json
import os
import time
import pandas as pd
from tqdm import tqdm
from nba_api.stats.endpoints import leaguegamefinder, boxscoretraditionalv3

RAW_DIR = "data/raw"
EXPECTED_COLUMNS = [
    "GAME_ID", "TEAM_ID", "PERSON_ID", "PLAYER_NAME",
    "START_POSITION", "COMMENT", "MIN", "FGM", "FGA", "FG_PCT",
    "FG3M", "FG3A", "FG3_PCT", "FTM", "FTA", "FT_PCT",
    "OREB", "DREB", "REB", "AST", "STL", "BLK", "TOV", "PF", "PTS",
    "PLUS_MINUS",
]


def _parse_boxscore(data: dict) -> list[dict]:
    records = []
    game_id = data.get("gameId")

    for team_key in ("homeTeam", "awayTeam"):
        team = data.get(team_key, {})
        team_id = team.get("teamId")

        for player in team.get("players", []):
            stats = player.get("statistics", {})
            mapped_stats = {
                "GAME_ID": game_id,
                "TEAM_ID": team_id,
                "PERSON_ID": player.get("personId"),
                "PLAYER_NAME": f"{player.get('firstName', '')} {player.get('familyName', '')}".strip(),
                "START_POSITION": player.get("position"),
                "COMMENT": player.get("comment"),
                "MIN": stats.get("minutes"),
                "FGM": stats.get("fieldGoalsMade"),
                "FGA": stats.get("fieldGoalsAttempted"),
                "FG_PCT": stats.get("fieldGoalsPercentage"),
                "FG3M": stats.get("threePointersMade"),
                "FG3A": stats.get("threePointersAttempted"),
                "FG3_PCT": stats.get("threePointersPercentage"),
                "FTM": stats.get("freeThrowsMade"),
                "FTA": stats.get("freeThrowsAttempted"),
                "FT_PCT": stats.get("freeThrowsPercentage"),
                "OREB": stats.get("reboundsOffensive"),
                "DREB": stats.get("reboundsDefensive"),
                "REB": stats.get("reboundsTotal"),
                "AST": stats.get("assists"),
                "STL": stats.get("steals"),
                "BLK": stats.get("blocks"),
                "TOV": stats.get("turnovers"),
                "PF": stats.get("foulsPersonal"),
                "PTS": stats.get("points"),
                "PLUS_MINUS": stats.get("plusMinusPoints"),
            }
            records.append(mapped_stats)

    return records


vars = json.loads(os.environ.get("BRUIN_VARS", "{}"))
start_date = str(vars.get("start_date", "2025-10-01"))
end_date = str(vars.get("end_date", "2025-10-07"))

print(f"Fetching box scores for games from {start_date} to {end_date}...")

frames = []
for season_type in ("Regular Season", "Playoffs"):
    gamefinder = leaguegamefinder.LeagueGameFinder(
        season_nullable="2025-26",
        season_type_nullable=season_type,
        player_or_team_abbreviation="T",
    )
    frames.append(gamefinder.get_data_frames()[0])

df = pd.concat(frames, ignore_index=True).drop_duplicates(subset="GAME_ID")
if df.empty:
    print("No games found from API.")
    os.makedirs(RAW_DIR, exist_ok=True)
    pd.DataFrame(columns=EXPECTED_COLUMNS).to_parquet(f"{RAW_DIR}/raw__box_scores.parquet", index=False)
else:
    df["GAME_DATE"] = pd.to_datetime(df["GAME_DATE"]).dt.strftime("%Y-%m-%d")
    game_ids = df.query(
        f"GAME_DATE >= '{start_date}' and GAME_DATE <= '{end_date}'"
    )["GAME_ID"].unique().tolist()

    if not game_ids:
        print(f"No games found in date range {start_date} to {end_date}.")
        os.makedirs(RAW_DIR, exist_ok=True)
        pd.DataFrame(columns=EXPECTED_COLUMNS).to_parquet(f"{RAW_DIR}/raw__box_scores.parquet", index=False)
    else:
        print(f"Found {len(game_ids)} games to fetch box scores for.")

        all_records = []
        for game_id in tqdm(game_ids, desc="Fetching box scores"):
            try:
                boxscore = boxscoretraditionalv3.BoxScoreTraditionalV3(game_id=game_id)
                data = boxscore.get_dict().get("boxScoreTraditional")
                if data is None:
                    continue
                all_records.extend(_parse_boxscore(data))
                time.sleep(2.5)
            except Exception as e:
                tqdm.write(f"  Error fetching game {game_id}: {e}")
                continue

        if not all_records:
            print("No box score data collected.")
            os.makedirs(RAW_DIR, exist_ok=True)
            pd.DataFrame(columns=EXPECTED_COLUMNS).to_parquet(f"{RAW_DIR}/raw__box_scores.parquet", index=False)
        else:
            result = pd.DataFrame(all_records)
            available = [c for c in EXPECTED_COLUMNS if c in result.columns]
            result = result[available]
            numeric_cols = [c for c in available if c not in ("GAME_ID", "PLAYER_NAME", "START_POSITION", "COMMENT")]
            for col in numeric_cols:
                result[col] = pd.to_numeric(result[col], errors="coerce")

            os.makedirs(RAW_DIR, exist_ok=True)
            result.to_parquet(f"{RAW_DIR}/raw__box_scores.parquet", index=False)
            print(f"Saved {len(result)} player-game records")
