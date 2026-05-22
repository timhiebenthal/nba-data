"""@bruin
name: raw.raw_teams
connection: nba_duckdb
@bruin"""

import os
import pandas as pd
from nba_api.stats.static import teams

RAW_DIR = "data/raw/raw__teams"

os.makedirs(RAW_DIR, exist_ok=True)
df = pd.DataFrame(teams.get_teams())
df.to_parquet(f"{RAW_DIR}/static.parquet", index=False)
print(f"Saved {len(df)} teams")
