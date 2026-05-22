/* @bruin
name: core.core__game_stats
connection: nba_duckdb
type: duckdb.sql

depends:
  - clean.clean__box_scores
  - clean.clean__players
  - clean.clean__teams

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
    b.GAME_ID::varchar AS GAME_ID,
    b.TEAM_ID::integer AS TEAM_ID,
    t.full_name::varchar AS TEAM_NAME,
    t.abbreviation::varchar AS TEAM_ABBREVIATION,
    b.PERSON_ID::integer AS PERSON_ID,
    b.PLAYER_NAME::varchar AS PLAYER_NAME,
    p.full_name::varchar AS PLAYER_FULL_NAME,
    b.START_POSITION::varchar AS START_POSITION,
    b.COMMENT::varchar AS COMMENT,
    b.MIN::varchar AS MIN,
    b.FGM::integer AS FGM,
    b.FGA::integer AS FGA,
    b.FG_PCT::float AS FG_PCT,
    b.FG3M::integer AS FG3M,
    b.FG3A::integer AS FG3A,
    b.FG3_PCT::float AS FG3_PCT,
    b.FTM::integer AS FTM,
    b.FTA::integer AS FTA,
    b.FT_PCT::float AS FT_PCT,
    b.OREB::integer AS OREB,
    b.DREB::integer AS DREB,
    b.REB::integer AS REB,
    b.AST::integer AS AST,
    b.STL::integer AS STL,
    b.BLK::integer AS BLK,
    b.TOV::integer AS TOV,
    b.PF::integer AS PF,
    b.PTS::integer AS PTS,
    b.PLUS_MINUS::float AS PLUS_MINUS
FROM clean.clean__box_scores b
LEFT JOIN clean.clean__players p ON b.person_id = p.id
LEFT JOIN clean.clean__teams t ON b.team_id = t.id
