/* @bruin
name: clean.clean__play_by_play
connection: nba_duckdb
type: duckdb.sql

depends:
  - raw.raw_play_by_play

materialization:
  type: table
  strategy: create+replace

columns:
  - name: GAME_ID
    type: varchar
    primary_key: true
  - name: ACTION_NUMBER
    type: integer
    primary_key: true
@bruin */

select
    game_id,
    clock, -- split into minutes and seconds or time
    period,
    team_id,
    team_tricode,
    person_id as player_id,
    x_legacy as position_x,
    y_legacy as position_y,
    shot_distance,
    shot_result,
    cast(is_field_goal as bool) as is_field_goal,
    score_home,
    score_away,
    --location, --tbd what it does,
    action_type,
    sub_type as action_sub_type,
    shot_value
    --action_id, -- tbd
    --action_number -- tbd
from read_parquet('data/raw/raw__play_by_play.parquet')
