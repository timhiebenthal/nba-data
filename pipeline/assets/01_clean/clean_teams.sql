-- @bruin
-- name: clean.clean_teams
-- connection: nba_duckdb
-- materialization:
--   type: table
--   strategy: create+replace
-- @bruin

SELECT *
FROM raw.raw_teams
