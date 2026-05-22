"""@bruin
name: raw.games
connection: nba_duckdb

materialization:
  type: table
  strategy: merge

columns:
  - name: GAME_ID
    type: varchar
    primary_key: true
  - name: TEAM_ID
    type: integer
    primary_key: true
@bruin"""

import json
import os
import pandas as pd
from nba_api.stats.endpoints import leaguegamefinder


def materialize() -> pd.DataFrame:
    """Fetch all team-game records for the given date range.

    The LeagueGameFinder returns one row per team per game (home and away
    are separate rows). This asset keeps that grain — no pivoting or joins.
    """
    vars = json.loads(os.environ.get("BRUIN_VARS", "{}"))
    start_date = str(vars.get("start_date", "2025-10-01"))
    end_date = str(vars.get("end_date", "2025-10-07"))

    print(f"Fetching games from {start_date} to {end_date}...")

    gamefinder = leaguegamefinder.LeagueGameFinder(
        season_nullable="2025-26",
        season_type_nullable="Regular Season",
        player_or_team_abbreviation="T",
    )

    df = gamefinder.get_data_frames()[0]

    if df.empty:
        print("No games found from API.")
        return pd.DataFrame()

    # Standardize types and filter by date range
    df["GAME_DATE"] = pd.to_datetime(df["GAME_DATE"]).dt.strftime("%Y-%m-%d")
    games = df.query(f"GAME_DATE >= '{start_date}' and GAME_DATE <= '{end_date}'")

    if games.empty:
        print(f"No games found in date range {start_date} to {end_date}.")
        return pd.DataFrame()

    # Keep only relevant columns, no joins or pivoting
    result = games[[
        "GAME_ID", "GAME_DATE", "TEAM_ID", "TEAM_NAME",
        "TEAM_ABBREVIATION", "MATCHUP", "WL", "PTS", "SEASON_ID"
    ]].copy()

    result["SEASON"] = result["SEASON_ID"].str[:4] + "-" + result["SEASON_ID"].str[4:]

    print(f"Returning {len(result)} team-game records.")
    return result
