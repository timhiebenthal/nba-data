/* @bruin
name: clean__teams
connection: nba_duckdb
type: duckdb.sql

depends:
  - raw.raw_teams

materialization:
  type: table
  strategy: create+replace
@bruin */

SELECT *
FROM "raw".raw_teams
