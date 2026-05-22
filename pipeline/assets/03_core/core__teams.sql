/* @bruin
name: core.core__teams
connection: nba_duckdb
type: duckdb.sql

depends:
  - clean.clean__teams

materialization:
  type: table
  strategy: create+replace

columns:
  - name: id
    type: integer
    primary_key: true
    description: The unique identifier of the team.
  - name: full_name
    type: varchar
    description: The full name of the team.
  - name: abbreviation
    type: varchar
    description: The team abbreviation (e.g., LAL, BOS).
  - name: nickname
    type: varchar
    description: The team nickname (e.g., Lakers, Celtics).
  - name: city
    type: varchar
    description: The team city.
  - name: state
    type: varchar
    description: The team state.
  - name: year_founded
    type: integer
    description: The year the team was founded.
@bruin */

SELECT
    id::integer AS id,
    full_name::varchar AS full_name,
    abbreviation::varchar AS abbreviation,
    nickname::varchar AS nickname,
    city::varchar AS city,
    state::varchar AS state,
    year_founded::integer AS year_founded
FROM clean.clean__teams
