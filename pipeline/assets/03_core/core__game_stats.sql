/* @bruin
name: core__game_stats
connection: nba_duckdb
type: duckdb.sql

depends:
  - clean__box_scores
  - clean__players
  - clean__teams

materialization:
  type: table
  strategy: create+replace

columns:
  - name: GAME_ID
    type: varchar
    primary_key: true
  - name: PERSON_ID
    type: integer
    primary_key: true
@bruin */

SELECT
    b.game_id::varchar AS game_id,
    b.team_id::integer AS team_id,
    t.full_name::varchar AS team_name,
    t.abbreviation::varchar AS team_abbreviation,
    b.person_id::integer AS person_id,
    b.player_name::varchar AS player_name,
    p.full_name::varchar AS player_full_name,
    b.start_position::varchar AS start_position,
    b.comment::varchar AS comment,
    b.min::varchar AS min,
    b.fgm::integer AS fgm,
    b.fga::integer AS fga,
    b.fg_pct::float AS fg_pct,
    b.fg3_m::integer AS fg3_m,
    b.fg3_a::integer AS fg3_a,
    b.fg3_pct::float AS fg3_pct,
    b.ftm::integer AS ftm,
    b.fta::integer AS fta,
    b.ft_pct::float AS ft_pct,
    b.oreb::integer AS oreb,
    b.dreb::integer AS dreb,
    b.reb::integer AS reb,
    b.ast::integer AS ast,
    b.stl::integer AS stl,
    b.blk::integer AS blk,
    b.tov::integer AS tov,
    b.pf::integer AS pf,
    b.pts::integer AS pts,
    b.plus_minus::float AS plus_minus
FROM clean__box_scores b
LEFT JOIN clean__players p ON b.person_id = p.id
LEFT JOIN clean__teams t ON b.team_id = t.id
