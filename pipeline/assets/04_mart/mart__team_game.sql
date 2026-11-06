/* @bruin

name: mart.mart__team_game
connection: nba_duckdb
type: duckdb.sql

description: |
  One row per team per game (long format), so dashboard filters on team_name hit the
  game log as well as the play-by-play widgets. Derived from core.dim__game by
  unpivoting the home/away sides.

depends:
  - core.dim__game
  - core.dim__team

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
  - name: team_id
    type: bigint
    description: "Team the row belongs to (home or away side of the game)"
    primary_key: true
    checks:
      - name: not_null
  - name: game_date
    type: date
    description: "Date the game was played"
  - name: season
    type: varchar
    description: "Season the game belongs to (e.g. '2025-26')"
  - name: matchup
    type: varchar
    description: "Home-team matchup string from the API (e.g. 'UTA vs. IND')"
  - name: team_name
    type: varchar
    description: "Full name of the team"
  - name: team_abbreviation
    type: varchar
    description: "3-letter abbreviation for the team"
  - name: opponent_team_name
    type: varchar
    description: "Full name of the opposing team"
  - name: opponent_team_abbreviation
    type: varchar
    description: "3-letter abbreviation for the opposing team"
  - name: versus
    type: varchar
    description: "Opponent label from this team's point of view ('vs. IND' at home, '@ IND' away)"
  - name: is_home
    type: boolean
    description: "Whether the team played at home"
  - name: points_for
    type: bigint
    description: "Points scored by this team"
  - name: points_against
    type: bigint
    description: "Points scored by the opponent"
  - name: pts_margin
    type: bigint
    description: "Points for minus points against"
  - name: is_win
    type: boolean
    description: "Whether this team won the game"
  - name: is_close_game
    type: boolean
    description: "Whether the final margin was within 10 points"
  - name: is_blowout_game
    type: boolean
    description: "Whether the final margin was 25 points or more"

custom_checks:
  - name: unique_team_game
    description: "Composite PK game_id + team_id must be unique (detects fanout)"
    query: SELECT game_id, team_id FROM mart.mart__team_game GROUP BY game_id, team_id HAVING COUNT(*) > 1
    count: 0
  - name: two_rows_per_game
    description: "Every game must appear exactly twice, once per team"
    query: SELECT game_id FROM mart.mart__team_game GROUP BY game_id HAVING COUNT(*) <> 2
    count: 0
@bruin */
with
    games as (
        select
            game_id,
            game_date,
            season,
            matchup,
            home_team_id,
            away_team_id,
            home_pts,
            away_pts,
            pts_margin,
            is_close_game,
            is_blowout_game
        from core.dim__game
    ),

    home as (
        select
            game_id,
            game_date,
            season,
            matchup,
            home_team_id as team_id,
            away_team_id as opponent_team_id,
            true as is_home,
            home_pts as points_for,
            away_pts as points_against,
            pts_margin,
            is_close_game,
            is_blowout_game
        from games
    ),

    away as (
        select
            game_id,
            game_date,
            season,
            matchup,
            away_team_id as team_id,
            home_team_id as opponent_team_id,
            false as is_home,
            away_pts as points_for,
            home_pts as points_against,
            pts_margin * -1 as pts_margin,
            is_close_game,
            is_blowout_game
        from games
    ),

    sides as (
        select *
        from home
        union all
        select *
        from away
    )

select
    sides.game_id,
    sides.team_id,
    sides.game_date,
    sides.season,
    sides.matchup,
    team.team_name,
    team.team_abbreviation,
    opponent.team_name as opponent_team_name,
    opponent.team_abbreviation as opponent_team_abbreviation,
    case
        when sides.is_home then 'vs. ' || opponent.team_abbreviation else '@ ' || opponent.team_abbreviation
    end as versus,
    sides.is_home,
    sides.points_for,
    sides.points_against,
    sides.pts_margin,
    sides.points_for > sides.points_against as is_win,
    sides.is_close_game,
    sides.is_blowout_game
from sides
left join core.dim__team as team on sides.team_id = team.team_id
left join core.dim__team as opponent on sides.opponent_team_id = opponent.team_id
