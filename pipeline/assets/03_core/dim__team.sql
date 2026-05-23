/* @bruin

name: core.dim__team
connection: nba_duckdb
type: duckdb.sql

depends:
  - prep.prep__team

materialization:
  type: table
  strategy: create+replace
@bruin */
select team_id, team_name, team_abbreviation, team_city, team_nickname, team_year_founded from prep.prep__team
