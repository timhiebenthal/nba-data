/* @bruin
name: prep.prep__team
connection: nba_duckdb
type: duckdb.sql

depends:
  - clean.clean__teams

materialization:
  type: table
  strategy: create+replace
@bruin */
select *, split_part(team_name, ' ', -1) as team_nickname from clean.clean__teams
