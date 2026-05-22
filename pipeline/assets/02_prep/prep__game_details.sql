/* @bruin
name: prep.prep__game_details
connection: nba_duckdb
type: duckdb.sql

depends:
  - clean.clean__games
  - clean.clean__teams

materialization:
  type: table
  strategy: create+replace
@bruin */

WITH games_with_teams AS (
    SELECT
        g.game_id,
        g.game_date,
        g.team_id,
        t.full_name AS team_name,
        t.abbreviation AS team_abbrev,
        g.matchup,
        g.wl,
        g.pts,
        g.season_id,
        g.season
    FROM clean.clean__games g
    LEFT JOIN clean.clean__teams t ON g.team_id = t.id
),
home_games AS (
    SELECT 
        game_id,
        game_date,
        team_id AS home_team_id,
        team_name AS home_team_name,
        team_abbrev AS home_team_abbrev,
        wl AS home_team_wl,
        pts AS home_team_pts,
        season_id,
        season
    FROM games_with_teams
    WHERE matchup LIKE '%vs.%'
),
away_games AS (
    SELECT 
        game_id,
        team_id AS away_team_id,
        team_name AS away_team_name,
        team_abbrev AS away_team_abbrev,
        wl AS away_team_wl,
        pts AS away_team_pts
    FROM games_with_teams
    WHERE matchup LIKE '%@%'
)
SELECT 
    h.game_id,
    h.game_date,
    h.season_id,
    h.season,
    h.home_team_id,
    h.home_team_name,
    h.home_team_abbrev,
    h.home_team_pts,
    h.home_team_wl,
    a.away_team_id,
    a.away_team_name,
    a.away_team_abbrev,
    a.away_team_pts,
    a.away_team_wl
FROM home_games h
LEFT JOIN away_games a ON h.game_id = a.game_id
