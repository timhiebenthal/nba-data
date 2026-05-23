/* @bruin
name: prep.prep__play_by_play
connection: nba_duckdb
type: duckdb.sql

depends:
  - clean.clean__play_by_play
@bruin */
select
    game_id,
    clock_minutes,
    clock_seconds_decimal,
    case
        when clock_minutes is not null then make_interval(minutes => clock_minutes, seconds => clock_seconds_decimal)
    end as clock_interval,
    period,
    team_id,
    team_tricode,
    player_id,
    position_x,
    position_y,
    shot_distance,
    shot_result,
    is_field_goal,
    score_home,
    score_away,
    action_type,
    action_sub_type,
    shot_value
from clean.clean__play_by_play
