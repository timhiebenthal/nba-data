/* @bruin

name: core.dim__game
connection: nba_duckdb
type: duckdb.sql

depends:
  - prep.prep__game

materialization:
  type: table
  strategy: create+replace

columns:
  - name: game_id
    type: varchar
    description: "Unique identifier for the NBA game"
    primary_key: true
    checks:
      - name: unique
      - name: not_null
  - name: game_date
    type: date
    description: "Date the game was played"
  - name: home_team_id
    type: integer
    description: "Team ID of the home team"
  - name: away_team_id
    type: integer
    description: "Team ID of the away team"
  - name: matchup
    type: varchar
    description: "Matchup string from home team perspective (e.g. 'LAL vs. GSW')"
  - name: home_pts
    type: integer
    description: "Points scored by the home team"
  - name: away_pts
    type: integer
    description: "Points scored by the away team"
  - name: pts_margin
    type: integer
    description: "Point differential from home team perspective (home_pts - away_pts)"
  - name: pts_margin_absolute
    type: integer
    description: "Absolute point differential"
  - name: is_close_game
    type: boolean
    description: "Whether the game was within 10 points"
  - name: is_blowout_game
    type: boolean
    description: "Whether the game was a 25+ point margin"
  - name: season_id
    type: varchar
    description: "NBA season identifier"
  - name: season
    type: varchar
    description: "Season label (e.g. '2025-26')"
@bruin */
with
    home_team as (
        select game_id, game_date, team_id as home_team_id, pts as home_pts, matchup, season_id, season
        from prep.prep__game
        where
            case
                when matchup like '%vs.%' and split_part(matchup, ' vs. ', 1) = team_abbreviation
                then 'home'
                when matchup like '%vs.%' and split_part(matchup, ' vs. ', 2) = team_abbreviation
                then 'away'
                when matchup like '%@%' and split_part(matchup, ' @ ', 1) = team_abbreviation
                then 'away'
                when matchup like '%@%' and split_part(matchup, ' @ ', 2) = team_abbreviation
                then 'home'
            end
            = 'home'
    ),

    away_team as (
        select game_id, team_id as away_team_id, pts as away_pts
        from prep.prep__game
        where
            case
                when matchup like '%vs.%' and split_part(matchup, ' vs. ', 1) = team_abbreviation
                then 'home'
                when matchup like '%vs.%' and split_part(matchup, ' vs. ', 2) = team_abbreviation
                then 'away'
                when matchup like '%@%' and split_part(matchup, ' @ ', 1) = team_abbreviation
                then 'away'
                when matchup like '%@%' and split_part(matchup, ' @ ', 2) = team_abbreviation
                then 'home'
            end
            = 'away'
    )

select
    h.game_id,
    h.game_date,
    h.home_team_id,
    a.away_team_id,
    h.matchup,
    h.home_pts,
    a.away_pts,
    h.home_pts - a.away_pts as pts_margin,
    abs(h.home_pts - a.away_pts) as pts_margin_absolute,
    abs(h.home_pts - a.away_pts) <= 10 as is_close_game,
    abs(h.home_pts - a.away_pts) >= 25 as is_blowout_game,
    h.season_id,
    h.season
from home_team as h
inner join away_team as a using (game_id)
