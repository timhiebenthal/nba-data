/* @bruin
name: clean__players
connection: nba_duckdb
type: duckdb.sql

depends:
  - raw.raw_players

materialization:
  type: table
  strategy: create+replace
@bruin */

SELECT *
FROM "raw".raw_players
