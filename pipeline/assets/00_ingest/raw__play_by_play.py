"""@bruin
name: raw.raw_play_by_play
connection: nba_duckdb
@bruin"""

import json
import os
import time
import random
from concurrent.futures import ThreadPoolExecutor, as_completed

import pandas as pd
from tqdm import tqdm
from nba_api.stats.endpoints import leaguegamefinder, playbyplayv3

RAW_DIR = "data/raw"
EXPECTED_COLUMNS = [
    "GAME_ID", "ACTION_NUMBER", "CLOCK", "PERIOD",
    "TEAM_ID", "TEAM_TRICODE", "PERSON_ID", "PLAYER_NAME", "PLAYER_NAME_I",
    "X_LEGACY", "Y_LEGACY", "SHOT_DISTANCE", "SHOT_RESULT", "IS_FIELD_GOAL",
    "SCORE_HOME", "SCORE_AWAY", "POINTS_TOTAL",
    "LOCATION", "DESCRIPTION", "ACTION_TYPE", "SUB_TYPE",
    "VIDEO_AVAILABLE", "SHOT_VALUE", "ACTION_ID",
]

MAX_WORKERS = 3
REQUEST_DELAY = 2.5


def _parse_actions(game_id: str, actions: list[dict]) -> list[dict]:
    records = []
    for action in actions:
        if not isinstance(action, dict):
            continue
        records.append({
            "GAME_ID": game_id,
            "ACTION_NUMBER": action.get("actionNumber"),
            "CLOCK": action.get("clock"),
            "PERIOD": action.get("period"),
            "TEAM_ID": action.get("teamId"),
            "TEAM_TRICODE": action.get("teamTricode"),
            "PERSON_ID": action.get("personId"),
            "PLAYER_NAME": action.get("playerName"),
            "PLAYER_NAME_I": action.get("playerNameI"),
            "X_LEGACY": action.get("xLegacy"),
            "Y_LEGACY": action.get("yLegacy"),
            "SHOT_DISTANCE": action.get("shotDistance"),
            "SHOT_RESULT": action.get("shotResult"),
            "IS_FIELD_GOAL": action.get("isFieldGoal"),
            "SCORE_HOME": action.get("scoreHome"),
            "SCORE_AWAY": action.get("scoreAway"),
            "POINTS_TOTAL": action.get("pointsTotal"),
            "LOCATION": action.get("location"),
            "DESCRIPTION": action.get("description"),
            "ACTION_TYPE": action.get("actionType"),
            "SUB_TYPE": action.get("subType"),
            "VIDEO_AVAILABLE": action.get("videoAvailable"),
            "SHOT_VALUE": action.get("shotValue"),
            "ACTION_ID": action.get("actionId"),
        })
    return records


def _fetch_game(game_id: str) -> list[dict]:
    time.sleep(random.uniform(0, 1))
    try:
        pbp = playbyplayv3.PlayByPlayV3(game_id=game_id)
        data = pbp.get_dict()
        actions = data.get("game", {}).get("actions", [])

        if not actions:
            return []

        return _parse_actions(game_id, actions)

    except Exception as e:
        tqdm.write(f"  Error fetching game {game_id}: {e}")
        return []
    finally:
        time.sleep(REQUEST_DELAY)


vars = json.loads(os.environ.get("BRUIN_VARS", "{}"))
start_date = str(vars.get("start_date", "2025-10-01"))
end_date = str(vars.get("end_date", "2025-10-07"))

print(f"Fetching play-by-play for games from {start_date} to {end_date}...")

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
    pd.DataFrame(columns=EXPECTED_COLUMNS).to_parquet(f"{RAW_DIR}/raw__play_by_play.parquet", index=False)
else:
    df["GAME_DATE"] = pd.to_datetime(df["GAME_DATE"]).dt.strftime("%Y-%m-%d")
    game_ids = df.query(
        f"GAME_DATE >= '{start_date}' and GAME_DATE <= '{end_date}'"
    )["GAME_ID"].unique().tolist()

    if not game_ids:
        print(f"No games found in date range {start_date} to {end_date}.")
        os.makedirs(RAW_DIR, exist_ok=True)
        pd.DataFrame(columns=EXPECTED_COLUMNS).to_parquet(f"{RAW_DIR}/raw__play_by_play.parquet", index=False)
    else:
        print(f"Found {len(game_ids)} games to fetch play-by-play for (concurrency={MAX_WORKERS}).")

        all_records = []
        with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
            futures = {executor.submit(_fetch_game, gid): gid for gid in game_ids}
            with tqdm(total=len(game_ids), desc="Fetching play-by-play") as pbar:
                for future in as_completed(futures):
                    records = future.result()
                    if records:
                        all_records.extend(records)
                    pbar.update(1)

        if not all_records:
            print("No play-by-play data collected.")
            os.makedirs(RAW_DIR, exist_ok=True)
            pd.DataFrame(columns=EXPECTED_COLUMNS).to_parquet(f"{RAW_DIR}/raw__play_by_play.parquet", index=False)
        else:
            result = pd.DataFrame(all_records)
            available = [c for c in EXPECTED_COLUMNS if c in result.columns]
            result = result[available]
            numeric_cols = [
                "ACTION_NUMBER", "PERIOD", "TEAM_ID", "PERSON_ID",
                "X_LEGACY", "Y_LEGACY", "SHOT_DISTANCE", "IS_FIELD_GOAL",
                "SCORE_HOME", "SCORE_AWAY", "POINTS_TOTAL",
                "VIDEO_AVAILABLE", "SHOT_VALUE", "ACTION_ID",
            ]
            for col in numeric_cols:
                if col in result.columns:
                    result[col] = pd.to_numeric(result[col], errors="coerce")

            os.makedirs(RAW_DIR, exist_ok=True)
            result.to_parquet(f"{RAW_DIR}/raw__play_by_play.parquet", index=False)
            print(f"Saved {len(result)} play-by-play records")
