/* @bruin

name: core.fact__play_by_plays
connection: nba_duckdb
type: duckdb.sql

depends:
  - prep.prep__play_by_play
  - prep.prep__action

materialization:
  type: table
  strategy: create+replace

columns:
  - name: game_id
    type: varchar
    description: "Unique identifier for the NBA game"
    primary_key: true
  - name: team_id
    type: integer
    description: "Unique identifier for the team"
    primary_key: true
  - name: player_id
    type: bigint
    description: "Unique identifier for the player"
  - name: action_id
    type: varchar
    description: "Surrogate key identifying the action type and sub-type"
  - name: action_sequence
    type: bigint
    description: "Sequence number of the action within the game"
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
    type: integer
    description: "X coordinate of the action location on the court"
  - name: position_y
    type: integer
    description: "Y coordinate of the action location on the court"
  - name: shot_distance
    type: integer
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
    type: integer
    description: "Point value of the shot (2 or 3)"
  - name: is_made_field_goal
    type: boolean
    description: "Whether the action was a made field goal (2pt or 3pt)"
  - name: is_made_free_throw
    type: boolean
    description: "Whether the action was a made free throw"

custom_checks:
  - name: unique_play
    description: "game_id + action_sequence must be unique"
    query: SELECT game_id, action_sequence FROM core.fact__play_by_plays GROUP BY game_id, action_sequence HAVING COUNT(*) > 1
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
            play.is_made_free_throw
        from prep.prep__play_by_play as play
        left join prep.prep__action as act using (action_type, action_sub_type)
    )

select *
from plays
