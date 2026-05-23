/* @bruin

name: dim__player
connection: nba_duckdb
type: duckdb.sql

depends:
  - prep.prep__player

materialization:
  type: table
  strategy: create+replace
@bruin */
select player_id, player_name, player_first_name, player_last_name, is_active_player from prep.prep__player
