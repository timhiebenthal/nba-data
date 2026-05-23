/* @bruin
name: prep.prep__game
connection: nba_duckdb
type: duckdb.sql


materialization:
  type: table
  strategy: create+replace
@bruin */
select * from clean.clean__games where game_id = '0022500090'
