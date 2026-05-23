/* @bruin

name: core.dim__action
connection: nba_duckdb
type: duckdb.sql

depends:
  - prep.prep__action

materialization:
  type: table
  strategy: create+replace
@bruin */
select action_id, action_type, action_sub_type from prep.prep__action
