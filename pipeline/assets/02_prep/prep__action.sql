/* @bruin
name: prep.prep__action
connection: nba_duckdb
type: duckdb.sql

depends:
  - clean.clean__play_by_play

materialization:
  type: table
  strategy: create+replace

@bruin */
with
    get_unique_actions as (
        select distinct
            {{ generate_surrogate_key(['action_type', 'action_sub_type']) }} as action_id,
            coalesce(action_type, 'Unknown') as action_type,
            coalesce(action_sub_type, 'Unknown') as action_sub_type,
        -- potential clustering goes here
        from clean.clean__play_by_play
        order by action_type, action_sub_type
    )

select *
from get_unique_actions
