/* @bruin

name: mart.mart__play_by_play
connection: nba_duckdb
type: duckdb.sql

depends:
  - core.fact__play_by_plays
  - core.dim__action
  - core.dim__game
  - core.dim__team
  - core.dim__player

materialization:
  type: table
  strategy: create+replace
@bruin */
with
    plays as (
        select
            play.game_id,
            play.team_id,
            play.player_id,
            act.action_id,
            play.action_sequence,
            play.clock_minutes,
            play.clock_seconds_decimal,
            play.clock_interval,
            play.period,
            play.position_x,
            play.position_y,
            play.shot_distance,
            play.shot_result,
            play.is_field_goal,
            play.score_home,
            play.score_away,
            play.shot_value,
            team.team_name,
            team.team_abbreviation,
            team.team_city,
            team.team_nickname,
            team.team_year_founded,
            game.matchup,
            game.pts_margin,
            game.pts_margin_absolute,
            game.is_close_game,
            game.is_blowout_game,
            player.player_name,
            player.player_first_name,
            player.player_last_name,
            player.is_active_player

        from core.fact__play_by_plays as play
        left join core.dim__action as act using (action_id)
        left join core.dim__team as team using (team_id)
        left join core.dim__game as game using (game_id)
        left join core.dim__player as player using (player_id)
    )

select *
from plays
