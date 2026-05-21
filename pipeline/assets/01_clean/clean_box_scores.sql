-- @bruin
-- name: clean.clean_box_scores
-- connection: nba_duckdb
-- materialization:
--   type: table
--   strategy: merge
-- columns:
--   - name: GAME_ID
--     type: varchar
--     primary_key: true
--   - name: PERSON_ID
--     type: integer
--     primary_key: true
-- @bruin

SELECT *
FROM raw.raw_box_scores
