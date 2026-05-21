"""@bruin
name: load.players
connection: nba_duckdb

materialization:
  type: table
  strategy: create+replace
@bruin"""

import pandas as pd
from nba_api.stats.static import players


def materialize() -> pd.DataFrame:
    return pd.DataFrame(players.get_players())
