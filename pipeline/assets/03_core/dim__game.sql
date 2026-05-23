/* @bruin

name: core.dim__game
connection: nba_duckdb
type: duckdb.sql

depends:
  - prep.prep__game

materialization:
  type: table
  strategy: create+replace
@bruin */
-- TODO: Review grain once consumption patterns are clear.
-- Currently keeps game-team grain from prep (one row per team per game).
-- If marts need pure game grain, consider pivoting here or adding a bridge table.
select * from prep.prep__game
