/* @bruin
name: clean.clean__games
connection: nba_duckdb
type: duckdb.sql

depends:
  - raw.raw_games

materialization:
  type: table
  strategy: create+replace

columns:
  - name: GAME_ID
    type: varchar
    primary_key: true
  - name: TEAM_ID
    type: integer
    primary_key: true
@bruin */
select
    game_id,
    cast(game_date as date) as game_date,
    team_id,
    team_name,
    team_abbreviation,
    matchup,
    wl,
    pts,
    season_id,
    season
from read_parquet('data/raw/raw__games/*.parquet')
where game_id = '0022500090'
