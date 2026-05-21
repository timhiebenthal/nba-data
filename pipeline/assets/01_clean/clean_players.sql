/* @bruin
name: clean.players
connection: nba_duckdb
type: duckdb.sql

depends:
  - load.players

materialization:
  type: table
  strategy: create+replace
@bruin */

SELECT *
FROM load.players
