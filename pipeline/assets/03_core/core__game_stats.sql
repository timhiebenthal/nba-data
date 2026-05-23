/* @bruin
name: core.core__game_stats
connection: nba_duckdb
type: duckdb.sql

depends:
  - clean.clean__box_scores
  - clean.clean__players
  - clean.clean__teams

materialization:
  type: table
  strategy: create+replace

columns:
  - name: GAME_ID
    type: varchar
    primary_key: true
  - name: PERSON_ID
    type: integer
    primary_key: true
@bruin */
