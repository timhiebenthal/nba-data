/* @bruin
name: clean.clean__teams
connection: nba_duckdb
type: duckdb.sql

depends:
  - raw.raw_teams

materialization:
  type: table
  strategy: create+replace
@bruin */
select
    id as team_id,
    full_name as team_name,
    abbreviation as team_abbreviation,
    city as team_city,
    year_founded as team_year_founded
from read_parquet('data/raw/raw__teams/*.parquet')
