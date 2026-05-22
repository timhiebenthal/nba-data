/* @bruin
name: clean__play_by_play
connection: nba_duckdb
type: duckdb.sql

depends:
  - raw.raw_play_by_play

materialization:
  type: table
  strategy: create+replace

columns:
  - name: GAME_ID
    type: varchar
    primary_key: true
  - name: ACTION_NUMBER
    type: integer
    primary_key: true
@bruin */

SELECT *
FROM raw.raw_play_by_play
