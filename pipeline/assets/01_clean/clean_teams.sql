/* @bruin
name: clean.teams
connection: nba_duckdb
type: duckdb.sql

depends:
  - raw.teams

materialization:
  type: table
  strategy: create+replace
@bruin */

SELECT *
FROM raw.teams
