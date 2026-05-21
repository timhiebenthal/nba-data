-- @bruin
-- name: clean.clean_games
-- connection: nba_duckdb
-- materialization:
--   type: table
--   strategy: merge
-- columns:
--   - name: GAME_ID
--     type: varchar
--     primary_key: true
--   - name: TEAM_ID
--     type: integer
--     primary_key: true
-- @bruin

SELECT
    GAME_ID,
    GAME_DATE,
    TEAM_ID,
    TEAM_NAME,
    TEAM_ABBREVIATION,
    WL,
    PTS,
    SEASON_ID,
    SEASON
FROM raw.raw_games
