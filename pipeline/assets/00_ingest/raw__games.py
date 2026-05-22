"""@bruin
name: raw.raw_games
connection: nba_duckdb
@bruin"""

import json
import os
import pandas as pd
from nba_api.stats.endpoints import leaguegamefinder

RAW_DIR = "data/raw"

vars = json.loads(os.environ.get("BRUIN_VARS", "{}"))
start_date = str(vars.get("start_date", "2025-10-01"))
end_date = str(vars.get("end_date", "2025-10-07"))

print(f"Fetching games from {start_date} to {end_date}...")

frames = []
for season_type in ("Regular Season", "Playoffs"):
    gamefinder = leaguegamefinder.LeagueGameFinder(
        season_nullable="2025-26",
        season_type_nullable=season_type,
        player_or_team_abbreviation="T",
    )
    frames.append(gamefinder.get_data_frames()[0])

df = pd.concat(frames, ignore_index=True).drop_duplicates()

if df.empty:
    print("No games found from API.")
    os.makedirs(RAW_DIR, exist_ok=True)
    pd.DataFrame(columns=["GAME_ID", "GAME_DATE", "TEAM_ID", "TEAM_NAME",
        "TEAM_ABBREVIATION", "MATCHUP", "WL", "PTS", "SEASON_ID", "SEASON"]
    ).to_parquet(f"{RAW_DIR}/raw__games.parquet", index=False)
else:
    df["GAME_DATE"] = pd.to_datetime(df["GAME_DATE"]).dt.strftime("%Y-%m-%d")
    games = df.query(f"GAME_DATE >= '{start_date}' and GAME_DATE <= '{end_date}'")

    result = games[[
        "GAME_ID", "GAME_DATE", "TEAM_ID", "TEAM_NAME",
        "TEAM_ABBREVIATION", "MATCHUP", "WL", "PTS", "SEASON_ID"
    ]].copy()
    result = result.reset_index(drop=True)
    result["SEASON"] = result["SEASON_ID"].str[:4] + "-" + result["SEASON_ID"].str[4:]

    os.makedirs(RAW_DIR, exist_ok=True)
    result.to_parquet(f"{RAW_DIR}/raw__games.parquet", index=False)
    print(f"Saved {len(result)} team-game records")
