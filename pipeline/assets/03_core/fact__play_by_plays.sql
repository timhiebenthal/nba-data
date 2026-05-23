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
            play.period,
            play.position_x,
            play.position_y,
            play.shot_distance,
            play.shot_result,
            play.is_field_goal,
            play.score_home,
            play.score_away,
            play.shot_value
        from prep.prep__play_by_play as play
        left join prep.prep__action as act using (action_type, action_sub_type)
    )

select *
from plays
