/* @bruin
name: clean__box_scores
connection: nba_duckdb
type: duckdb.sql

depends:
  - raw.raw_box_scores

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
FROM "raw".raw_box_scores
