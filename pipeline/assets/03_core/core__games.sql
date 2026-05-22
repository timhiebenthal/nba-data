/* @bruin
name: core__games
connection: nba_duckdb
type: duckdb.sql

depends:
  - prep__game_details

materialization:
  type: table
  strategy: create+replace

columns:
  - name: game_id
    type: varchar
    primary_key: true
    description: The unique identifier of the game.
@bruin */

SELECT
    game_id::varchar AS game_id,
    game_date::date AS game_date,
    season_id::varchar AS season_id,
    season::varchar AS season,
    home_team_id::integer AS home_team_id,
    home_team_name::varchar AS home_team_name,
    home_team_abbrev::varchar AS home_team_abbrev,
    home_team_pts::integer AS home_team_pts,
    home_team_wl::varchar AS home_team_wl,
    away_team_id::integer AS away_team_id,
    away_team_name::varchar AS away_team_name,
    away_team_abbrev::varchar AS away_team_abbrev,
    away_team_pts::integer AS away_team_pts,
    away_team_wl::varchar AS away_team_wl
FROM prep__game_details
