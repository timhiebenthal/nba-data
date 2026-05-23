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
select
    game_id,
    max(game_date) as game_date,
    max(case when is_home_team then team_id end) as home_team_id,
    max(case when is_away_team then team_id end) as away_team_id,
    max(case when is_home_team then matchup end) as matchup,
    max(case when is_home_team then pts end) as home_pts,
    max(case when is_away_team then pts end) as away_pts,
    max(case when is_home_team then pts end) - max(case when is_away_team then pts end) as pts_margin,
    max(pts_margin_absolute) as pts_margin_absolute,
    max(is_close_game) as is_close_game,
    max(is_blowout_game) as is_blowout_game,
    max(season_id) as season_id,
    max(season) as season
from prep.prep__game
group by game_id
