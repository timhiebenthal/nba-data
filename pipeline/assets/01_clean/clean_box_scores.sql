/* @bruin
name: clean.box_scores
connection: nba_duckdb
type: duckdb.sql

depends:
  - load.box_scores

materialization:
  type: table
  strategy: merge

columns:
  - name: GAME_ID
    type: varchar
    primary_key: true
  - name: PERSON_ID
    type: integer
    primary_key: true
@bruin */

SELECT *
FROM load.box_scores
