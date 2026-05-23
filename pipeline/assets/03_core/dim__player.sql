/* @bruin

name: core.dim__player
connection: nba_duckdb
type: duckdb.sql

depends:
  - prep.prep__player

materialization:
  type: table
  strategy: create+replace

columns:
  - name: player_id
    type: bigint
    description: "Unique identifier for the player"
    primary_key: true
  - name: player_name
    type: varchar
    description: "Full name of the player"
  - name: player_first_name
    type: varchar
    description: "First name of the player"
  - name: player_last_name
    type: varchar
    description: "Last name of the player"
  - name: is_active_player
    type: boolean
    description: "Whether the player is currently active"
@bruin */
select player_id, player_name, player_first_name, player_last_name, is_active_player from prep.prep__player
