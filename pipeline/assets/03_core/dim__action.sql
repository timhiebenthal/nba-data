/* @bruin

name: core.dim__action
connection: nba_duckdb
type: duckdb.sql

depends:
  - prep.prep__action

materialization:
  type: table
  strategy: create+replace

columns:
  - name: action_id
    type: varchar
    description: "Surrogate key for the action type + sub-type combination"
    primary_key: true
  - name: action_type
    type: varchar
    description: "High-level category of the play action (e.g. 'Jump Ball', 'Layup')"
  - name: action_sub_type
    type: varchar
    description: "Refinement of the action type (e.g. 'Driving', 'Pullup')"
@bruin */
select action_id, action_type, action_sub_type from prep.prep__action
