/* @bruin

name: core.dim__team
connection: nba_duckdb
type: duckdb.sql

depends:
  - prep.prep__team

materialization:
  type: table
  strategy: create+replace

columns:
  - name: team_id
    type: integer
    description: "Unique identifier for the team"
    primary_key: true
  - name: team_name
    type: varchar
    description: "Full name of the team (e.g. 'Los Angeles Lakers')"
  - name: team_abbreviation
    type: varchar
    description: "3-letter abbreviation for the team (e.g. 'LAL')"
  - name: team_city
    type: varchar
    description: "City where the team is based (e.g. 'Los Angeles')"
  - name: team_nickname
    type: varchar
    description: "Nickname of the team (e.g. 'Lakers')"
  - name: team_year_founded
    type: bigint
    description: "Year the team was established"
@bruin */
select team_id, team_name, team_abbreviation, team_city, team_nickname, team_year_founded from prep.prep__team
