/* @bruin

name: mart.mart__player_game_shooting
connection: nba_duckdb
type: duckdb.sql

description: |
  One row per player per game with the shooting line aggregated out of
  mart.mart__play_by_play (~1.3M events collapsed to ~35k rows). This is the
  grain a shooting pivot wants: per-game averages are a count of rows, no
  DISTINCT game counting at query time.

  Plays with no team attribution (team_id 0: rebounds, timeouts, period markers;
  ~109k events with zero scoring attempts) are dropped here on purpose - a
  shooting split needs a team and a player to be meaningful.

depends:
  - mart.mart__play_by_play

materialization:
  type: table
  strategy: create+replace

columns:
  - name: game_id
    type: varchar
    description: "Unique identifier for the NBA game"
    primary_key: true
    checks:
      - name: not_null
  - name: player_id
    type: bigint
    description: "Unique identifier for the player"
    primary_key: true
    checks:
      - name: not_null
  - name: game_date
    type: date
    description: "Date the game was played"
  - name: matchup
    type: varchar
    description: "Matchup string from the API (e.g. 'UTA vs. IND')"
  - name: team_id
    type: bigint
    description: "Team the player appeared for in this game"
  - name: team_name
    type: varchar
    description: "Full name of the team"
  - name: team_abbreviation
    type: varchar
    description: "3-letter abbreviation for the team"
  - name: player_name
    type: varchar
    description: "Full name of the player"
  - name: points
    type: bigint
    description: "Points scored (field goals and free throws)"
  - name: fg2_attempts
    type: bigint
    description: "2-point field goal attempts"
  - name: fg2_made
    type: bigint
    description: "2-point field goals made"
  - name: fg3_attempts
    type: bigint
    description: "3-point field goal attempts"
  - name: fg3_made
    type: bigint
    description: "3-point field goals made"
  - name: ft_attempts
    type: bigint
    description: "Free throw attempts"
  - name: ft_made
    type: bigint
    description: "Free throws made"

custom_checks:
  - name: unique_player_game
    description: "Composite PK game_id + player_id must be unique (detects fanout)"
    query: SELECT game_id, player_id FROM mart.mart__player_game_shooting GROUP BY game_id, player_id HAVING COUNT(*) > 1
    count: 0
  - name: points_reconcile
    description: "Player-game points must add up to the play-by-play total for attributed plays"
    query: |
      SELECT 1
      FROM (
        SELECT SUM(points) AS shot_points
        FROM mart.mart__player_game_shooting
      ) AS summary
      CROSS JOIN (
        SELECT SUM(CASE WHEN is_made_score THEN shot_value ELSE 0 END) AS pbp_points
        FROM mart.mart__play_by_play
        WHERE team_name IS NOT NULL AND player_id IS NOT NULL
      ) AS reference
      WHERE summary.shot_points <> reference.pbp_points
    count: 0
@bruin */
with
    attributed as (
        select
            play.game_id,
            play.player_id,
            play.team_id,
            play.game_date,
            play.matchup,
            play.team_name,
            play.team_abbreviation,
            play.player_name,
            play.is_score_attempt,
            play.is_made_score,
            play.shot_value
        from mart.mart__play_by_play as play
        where play.team_name is not null and play.player_id is not null
    )

select
    game_id,
    player_id,
    game_date,
    matchup,
    team_id,
    team_name,
    team_abbreviation,
    player_name,
    sum(case when is_made_score then shot_value else 0 end) as points,
    count(case when is_score_attempt and shot_value = 2 then 1 end) as fg2_attempts,
    count(case when is_made_score and shot_value = 2 then 1 end) as fg2_made,
    count(case when is_score_attempt and shot_value = 3 then 1 end) as fg3_attempts,
    count(case when is_made_score and shot_value = 3 then 1 end) as fg3_made,
    count(case when is_score_attempt and shot_value = 1 then 1 end) as ft_attempts,
    count(case when is_made_score and shot_value = 1 then 1 end) as ft_made
from attributed
group by game_id, player_id, game_date, matchup, team_id, team_name, team_abbreviation, player_name
