/* @bruin
name: clean.clean__players
connection: nba_duckdb
type: duckdb.sql

depends:
  - raw.raw_players

materialization:
  type: table
  strategy: create+replace
@bruin */
select
    id as player_id,
    full_name as player_name,
    first_name as player_first_name,
    last_name as player_last_name,
    is_active as is_active_player
from read_parquet('data/raw/raw__players/*.parquet')
