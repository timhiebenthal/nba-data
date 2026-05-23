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
      - name: not_null
  - name: game_date
    type: date
    description: "Date the game was played"
  - name: team_id
    type: integer
    description: "Unique identifier for the team"
    primary_key: true
    checks:
      - name: not_null
  - name: team_name
    type: varchar
    description: "Full name of the team"
  - name: team_abbreviation
    type: varchar
    description: "3-letter abbreviation for the team"
  - name: matchup
    type: varchar
    description: "Matchup string (e.g. 'LAL vs. GSW' or 'LAL @ GSW')"
  - name: is_home_team
    type: boolean
    description: "Whether this row represents the home team"
  - name: is_away_team
    type: boolean
    description: "Whether this row represents the away team"
  - name: pts
    type: integer
    description: "Points scored by the team in this game"
  - name: wl
    type: varchar
    description: "Win/Loss result for the team ('W' or 'L')"
  - name: pts_margin
    type: integer
    description: "Point differential (team pts - opponent pts)"
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
  - name: opponent_team_id
    type: integer
    description: "The opposing team's identifier"
  - name: opponent_pts
    type: integer
    description: "Points scored by the opposing team"

custom_checks:
  - name: unique_game_team
    description: "Composite PK game_id + team_id must be unique"
    query: SELECT game_id, team_id FROM core.dim__game GROUP BY game_id, team_id HAVING COUNT(*) > 1
    count: 0
@bruin */
-- TODO: Review grain once consumption patterns are clear.
-- Currently keeps game-team grain from prep (one row per team per game).
-- If marts need pure game grain, consider pivoting here or adding a bridge table.
select * from prep.prep__game
