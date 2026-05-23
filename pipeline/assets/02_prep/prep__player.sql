/* @bruin
name: prep.prep__player
connection: nba_duckdb
type: duckdb.sql

depends:
  - clean.clean__players

materialization:
  type: table
  strategy: create+replace
@bruin */
select * from clean.clean__players
