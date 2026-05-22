"""@bruin
name: raw.raw_players
connection: nba_duckdb
@bruin"""

import os
import pandas as pd
from nba_api.stats.static import players

RAW_DIR = "data/raw/raw__players"

os.makedirs(RAW_DIR, exist_ok=True)
df = pd.DataFrame(players.get_players())
df.to_parquet(f"{RAW_DIR}/static.parquet", index=False)
print(f"Saved {len(df)} players")
