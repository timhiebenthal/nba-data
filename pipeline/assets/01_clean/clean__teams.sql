/* @bruin
name: clean.clean__teams
connection: nba_duckdb
type: duckdb.sql

depends:
  - raw.raw_teams

materialization:
  type: table
  strategy: create+replace
@bruin */

SELECT *
FROM read_parquet('data/raw/raw__teams.parquet')
