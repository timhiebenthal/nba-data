/* @bruin

name: mart.mart__play_by_play
connection: nba_duckdb
type: duckdb.sql

depends:
  - core.fact__play_by_plays
  - core.dim__action
  - core.dim__game
  - core.dim__team
  - core.dim__player

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
    type: bigint
    description: "Unique identifier for the team"
  - name: player_id
    type: bigint
    description: "Unique identifier for the player"
  - name: action_id
    type: varchar
    description: "Surrogate key identifying the action type and sub-type"
  - name: action_sequence
    type: bigint
    description: "Sequence number of the action within the game"
    primary_key: true
    checks:
      - name: not_null
  - name: clock_minutes
    type: integer
    description: "Minutes elapsed within the current period (counting up from 0)"
  - name: clock_seconds_decimal
    type: double
    description: "Seconds elapsed within the current period, decimal precision"
  - name: clock_interval
    type: interval
    description: "Interval representing elapsed time within the current period"
  - name: total_match_minutes
    type: integer
    description: "Total minutes elapsed since start of game (48min + OT), counting up from 0"
  - name: total_match_seconds_decimal
    type: double
    description: "Total seconds elapsed since start of game, decimal precision"
  - name: total_match_time_interval
    type: interval
    description: "Interval representing total elapsed game time"
  - name: period
    type: integer
    description: "Game period (1-4 for regulation, 5+ for overtime)"
  - name: position_x
    type: bigint
    description: "X coordinate of the action location on the court"
  - name: position_y
    type: bigint
    description: "Y coordinate of the action location on the court"
  - name: shot_distance
    type: bigint
    description: "Distance of the shot attempt in feet"
  - name: shot_result
    type: varchar
    description: "Whether the shot was 'Made' or 'Missed'"
  - name: is_field_goal
    type: boolean
    description: "Whether the action was a field goal attempt"
  - name: score_home
    type: double
    description: "Home team score after the action"
  - name: score_away
    type: double
    description: "Away team score after the action"
  - name: shot_value
    type: bigint
    description: "Point value of the shot (2 or 3)"
  - name: is_made_field_goal
    type: boolean
    description: "Whether the action was a made field goal (2pt or 3pt)"
  - name: is_made_free_throw
    type: boolean
    description: "Whether the action was a made free throw"
  - name: is_score_attempt
    type: boolean
    description: "Whether the action was a scoring attempt (field goal or free throw)"
  - name: is_made_score
    type: boolean
    description: "Whether the scoring attempt was successful (made FG or made FT)"
  - name: shot_type
    type: varchar
    description: "Type of scoring attempt: 'Field Goal' or 'Free Throw'"
  - name: action_type
    type: varchar
    description: "High-level category of the play action"
  - name: action_sub_type
    type: varchar
    description: "Refinement of the action type"
  - name: team_name
    type: varchar
    description: "Full name of the team"
  - name: team_abbreviation
    type: varchar
    description: "3-letter abbreviation for the team"
  - name: team_city
    type: varchar
    description: "City where the team is based"
  - name: team_nickname
    type: varchar
    description: "Nickname of the team"
  - name: team_year_founded
    type: bigint
    description: "Year the team was established"
  - name: matchup
    type: varchar
    description: "Matchup string (e.g. 'LAL vs. GSW')"
  - name: pts_margin
    type: bigint
    description: "Point differential at time of action"
  - name: pts_margin_absolute
    type: bigint
    description: "Absolute point differential at time of action"
  - name: is_close_game
    type: boolean
    description: "Whether the game was within 10 points"
  - name: is_blowout_game
    type: boolean
    description: "Whether the game was a 25+ point margin"
  - name: player_name
    type: varchar
    description: "Full name of the player"
  - name: player_first_name
    type: varchar
    description: "First name of the player"
  - name: player_last_name
    type: varchar
    description: "Last name of the player"
  - name: is_active_player
    type: boolean
    description: "Whether the player is currently active"
  - name: total_game_minutes
    type: integer
    description: "Total game minutes (48 regulation + 5 per OT period)"

custom_checks:
  - name: unique_play
    description: "Composite PK game_id + action_sequence must be unique (detects fanout)"
    query: SELECT game_id, action_sequence FROM mart.mart__play_by_play GROUP BY game_id, action_sequence HAVING COUNT(*) > 1
    count: 0
@bruin */
with
    plays as (
        select
            play.game_id,
            play.team_id,
            play.player_id,
            act.action_id,
            play.action_sequence,
            play.clock_minutes,
            play.clock_seconds_decimal,
            play.clock_interval,
            play.total_match_minutes,
            play.total_match_seconds_decimal,
            play.total_match_time_interval,
            play.period,
            play.position_x,
            play.position_y,
            play.shot_distance,
            play.shot_result,
            play.is_field_goal,
            play.score_home,
            play.score_away,
            play.shot_value,
            play.is_made_field_goal,
            play.is_made_free_throw,
            (play.is_field_goal or act.action_type = 'Free Throw') as is_score_attempt,
            (play.is_made_field_goal or play.is_made_free_throw) as is_made_score,
            case
                when play.is_field_goal then 'Field Goal' when act.action_type = 'Free Throw' then 'Free Throw'
            end as shot_type,
            act.action_type,
            act.action_sub_type,
            team.team_name,
            team.team_abbreviation,
            team.team_city,
            team.team_nickname,
            team.team_year_founded,
            game.game_date,
            game.matchup,
            game.pts_margin,
            game.pts_margin_absolute,
            game.is_close_game,
            game.is_blowout_game,
            player.player_name,
            player.player_first_name,
            player.player_last_name,
            player.is_active_player,
            game.total_minutes as total_game_minutes
        from core.fact__play_by_plays as play
        left join core.dim__action as act using (action_id)
        left join core.dim__team as team using (team_id)
        left join core.dim__game as game using (game_id)
        left join core.dim__player as player using (player_id)
    )

select *
from plays
