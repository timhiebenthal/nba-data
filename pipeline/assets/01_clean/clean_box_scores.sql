/* @bruin
name: clean.box_scores
connection: nba_duckdb
type: duckdb.sql

depends:
  - raw.box_scores

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

SELECT *
FROM "raw".box_scores
