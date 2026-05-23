/* @bruin
name: prep.prep__play_by_play
connection: nba_duckdb
type: duckdb.sql

depends:
  - clean.clean__play_by_play

materialization:
  type: table
  strategy: create+replace
@bruin */
with
    remaining as (
        select
            *,
            case when period <= 4 then 720 else 300 end as period_length_seconds,
            clock_minutes * 60 + clock_seconds_decimal as remaining_seconds
        from clean.clean__play_by_play
    ),

    elapsed as (
        select
            *,
            period_length_seconds - remaining_seconds as elapsed_in_period_seconds,
            case when period <= 4 then (period - 1) * 720 else 2880 + (period - 5) * 300 end as prior_periods_seconds
        from remaining
    )

select
    game_id,
    floor(elapsed_in_period_seconds / 60) as clock_minutes,
    elapsed_in_period_seconds % 60 as clock_seconds_decimal,
    case
        when clock_minutes is not null
        then
            (floor(elapsed_in_period_seconds / 60) * interval '1 minute')
            + (elapsed_in_period_seconds % 60 * interval '1 second')
    end as clock_interval,
    period,
    floor((prior_periods_seconds + elapsed_in_period_seconds) / 60) as total_match_minutes,
    (prior_periods_seconds + elapsed_in_period_seconds) % 60 as total_match_seconds_decimal,
    case
        when clock_minutes is not null
        then
            (floor((prior_periods_seconds + elapsed_in_period_seconds) / 60) * interval '1 minute')
            + ((prior_periods_seconds + elapsed_in_period_seconds) % 60 * interval '1 second')
    end as total_match_time_interval,
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
    action_sequence,
    action_type,
    action_sub_type,
    shot_value,
    shot_result = 'Made' and is_field_goal as is_made_field_goal,
    action_type = 'Free Throw' and shot_result = 'Made' as is_made_free_throw
from elapsed
