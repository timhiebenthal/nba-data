/* @bruin
name: prep.prep__game_details
connection: nba_duckdb
type: duckdb.sql

depends:
  - clean.clean__games
  - clean.clean__teams

materialization:
  type: table
  strategy: create+replace
@bruin */
