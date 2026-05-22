/* @bruin
name: clean__games
connection: nba_duckdb
type: duckdb.sql

depends:
  - raw.raw_games

materialization:
  type: table
  strategy: create+replace

columns:
  - name: GAME_ID
    type: varchar
    primary_key: true
  - name: TEAM_ID
    type: integer
    primary_key: true
@bruin */

SELECT
    GAME_ID,
    GAME_DATE,
    TEAM_ID,
    TEAM_NAME,
    TEAM_ABBREVIATION,
    MATCHUP,
    WL,
    PTS,
    SEASON_ID,
    SEASON
FROM "raw".raw_games
