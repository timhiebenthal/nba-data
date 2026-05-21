"""@bruin
name: raw.teams
connection: nba_duckdb

materialization:
  type: table
  strategy: create+replace
@bruin"""

import pandas as pd
from nba_api.stats.static import teams


def materialize() -> pd.DataFrame:
    return pd.DataFrame(teams.get_teams())
