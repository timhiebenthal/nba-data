/* @bruin
name: core.players
connection: nba_duckdb
type: duckdb.sql

depends:
  - clean.players

materialization:
  type: table
  strategy: create+replace

columns:
  - name: id
    type: integer
    primary_key: true
    description: The unique identifier of the player.
  - name: full_name
    type: varchar
    description: The full name of the player.
  - name: first_name
    type: varchar
    description: The first name of the player.
  - name: last_name
    type: varchar
    description: The last name of the player.
  - name: is_active
    type: boolean
    description: Whether the player is currently active in the NBA.
@bruin */

SELECT
    id::integer AS id,
    full_name::varchar AS full_name,
    first_name::varchar AS first_name,
    last_name::varchar AS last_name,
    is_active::boolean AS is_active
FROM clean.players
