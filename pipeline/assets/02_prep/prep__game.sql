/* @bruin
name: prep.prep__game
connection: nba_duckdb
type: duckdb.sql


materialization:
  type: table
  strategy: create+replace
@bruin */
with
    parse_home_away_team as (
        select
            game_id,
            game_date,
            team_id,
            team_abbreviation,
            left(matchup, 3) = team_abbreviation and matchup like '%@%' as is_away_team,
            left(matchup, 3) = team_abbreviation and matchup like '%vs.%' as is_home_team,
            matchup,
            pts,
            wl,
            season_id,
            season
        from clean.clean__games
    ),

    compose_full_score as (
        select
            {{ generate_surrogate_key(['team.game_id', 'team.team_id']) }} as game_team_id,
            team.*,
            opponent.team_id as opponent_team_id,
            opponent.pts as opponent_pts,
            team.pts - opponent.pts as pts_margin,
            abs(team.pts - opponent.pts) as pts_margin_absolute,
            abs(team.pts - opponent.pts) <= 10 as is_close_game,
            abs(team.pts - opponent.pts) >= 25 as is_blowout_game
        from parse_home_away_team as team
        left join
            parse_home_away_team as opponent on team.game_id = opponent.game_id and team.team_id != opponent.team_id
    )

select *
from compose_full_score
