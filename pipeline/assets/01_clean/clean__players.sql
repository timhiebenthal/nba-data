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

SELECT *
FROM read_parquet('data/raw/raw__players.parquet')
