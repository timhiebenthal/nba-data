/* @bruin
name: clean.players
connection: nba_duckdb
type: duckdb.sql

depends:
  - raw.players

materialization:
  type: table
  strategy: create+replace
@bruin */

SELECT *
FROM raw.players
