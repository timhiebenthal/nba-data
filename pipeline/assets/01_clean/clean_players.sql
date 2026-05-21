-- @bruin
-- name: clean.clean_players
-- connection: nba_duckdb
-- materialization:
--   type: table
--   strategy: create+replace
-- @bruin

SELECT *
FROM raw.raw_players
