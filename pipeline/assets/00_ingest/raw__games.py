"""@bruin
name: raw.raw_games
connection: nba_duckdb
@bruin"""

import calendar
import json
import os
from datetime import datetime

import pandas as pd
from nba_api.stats.endpoints import leaguegamefinder

RAW_DIR = "data/raw/raw__games"


def _month_keys(start_date: str, end_date: str) -> list[str]:
    """Return sorted list of YYYY-MM keys covering the date range."""
    start = datetime.strptime(start_date, "%Y-%m-%d").date()
    end = datetime.strptime(end_date, "%Y-%m-%d").date()
    keys: list[str] = []
    y, m = start.year, start.month
    while (y, m) <= (end.year, end.month):
        keys.append(f"{y}-{m:02d}")
        m += 1
        if m > 12:
            m = 1
            y += 1
    return keys


def _filter_and_write(df: pd.DataFrame, start_date: str, end_date: str) -> None:
    """Filter df by date range and write one parquet per month."""
    df["GAME_DATE"] = pd.to_datetime(df["GAME_DATE"]).dt.strftime("%Y-%m-%d")
    games = df.query(f"GAME_DATE >= '{start_date}' and GAME_DATE <= '{end_date}'").copy()

    if games.empty:
        os.makedirs(RAW_DIR, exist_ok=True)
        return

    games["SEASON"] = games["SEASON_ID"].str[:4] + "-" + games["SEASON_ID"].str[4:]

    for month_key in _month_keys(start_date, end_date):
        month_data = games[games["GAME_DATE"].str.startswith(month_key)]
        if month_data.empty:
            continue
        result = month_data[[
            "GAME_ID", "GAME_DATE", "TEAM_ID", "TEAM_NAME",
            "TEAM_ABBREVIATION", "MATCHUP", "WL", "PTS", "SEASON_ID", "SEASON"
        ]].reset_index(drop=True)
        os.makedirs(RAW_DIR, exist_ok=True)
        result.to_parquet(f"{RAW_DIR}/{month_key}.parquet", index=False)
        print(f"  Wrote {RAW_DIR}/{month_key}.parquet ({len(result)} rows)")


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
else:
    _filter_and_write(df, start_date, end_date)
