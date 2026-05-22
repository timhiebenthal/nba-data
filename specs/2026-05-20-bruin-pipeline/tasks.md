# Bruin NBA Data Pipeline - Implementation Tasks

## Overview

Migrate NBA data ingestion from Marimo notebook to Bruin pipeline with DuckDB target. Clean layer assets complete, following 4-layer transformation architecture (Clean → Prep → Core → Mart).

## Tasks

## SPRINT 1: Foundation

### Stream A: Install + .bruin.yml + pyproject.toml

- [x] Install Bruin CLI: `curl -LsSf https://getbruin.com/install/cli | sh`
- [x] Verify install: `bruin --version` returns version number
- [x] Create `.bruin.yml` with DuckDB connection named `nba_duckdb` pointing to `nba.duckdb` file
- [x] Create `pyproject.toml` at project root with dependencies: `nba_api`, `pandas`, `duckdb`, `tqdm`
- [x] Run `uv sync` to generate `uv.lock` and verify dependency resolution
- [x] Verify: `uv run python -c "from nba_api.stats.static import teams; print(teams.get_teams())"` returns team list

### Stream B: pipeline.yml + pipeline structure

- [x] Create `pipeline/` directory with `pipeline/assets/` subdirectory
- [x] Create `pipeline/pipeline.yml` with:
  - `name: nba-ingestion`
  - `variables` block: `start_date` (string, default "2025-10-21"), `end_date` (string, default "2025-10-27")
  - `default_connections` mapping duckdb to `nba_duckdb`
- [x] Run `bruin validate` to confirm pipeline is recognized
- [x] Verify: `bruin validate` exits 0 with no errors

### Stream C: Makefile

- [x] Create `Makefile` with targets: `init`, `run`, `run-dates`, `query`, `status`, `clean-db`
- [x] `run-dates` target passes `--var start_date=$(START) --var end_date=$(END)` to `bruin run`
- [x] Verify: `make status` runs `bruin validate` successfully

## SPRINT 2: Load Layer Assets

### Stream A: load_teams.py

- [x] Create `pipeline/assets/00_load/load_teams.py` with Bruin docstring header
- [x] Implement `materialize()` function calling `nba_api.stats.static.teams.get_teams()`
- [x] Run: `bruin run pipeline --selector "file:load_teams"`
- [x] Verify: 30 rows in `teams` table

### Stream B: load_players.py

- [x] Create `pipeline/assets/00_load/load_players.py` with Bruin docstring header
- [x] Implement `materialize()` function calling `nba_api.stats.static.players.get_players()`
- [x] Run: `bruin run pipeline --selector "file:load_players"`
- [x] Verify: 5103 rows in `players` table

### Stream C: load_games.py

- [x] Create `pipeline/assets/00_load/load_games.py` with Bruin docstring header
- [x] Implement `materialize()` with BRUIN_VARS date parsing, raw team-game grain (no pivoting)
- [x] Run: `bruin run pipeline --selector "file:load_games" --var 'start_date="2025-10-21"' --var 'end_date="2025-10-27"'`
- [x] Verify: 106 team-game records for Oct 21-27

### Stream D: load_box_scores.py

- [x] Create `pipeline/assets/load/load_box_scores.py` with Bruin docstring header
- [x] Implement `materialize()` with API game ID lookup and rate-limit delays (`time.sleep(2.5)`)
- [x] Run: `bruin run pipeline --selector "file:load_box_scores" --var 'start_date="2025-10-21"' --var 'end_date="2025-10-23"'`
- [x] Verify: 439 player-game records

## SPRINT 3: Prep + Core Layers

### Stream A: prep_game_details.sql

- [x] Create `pipeline/assets/02_prep/prep_game_details.sql`
- [x] Join `clean.games` with `clean.teams` to get team names
- [x] Pivot team-game rows to game-level rows (home/away on same row)
- [x] Run: `bruin run pipeline --selector "file:prep_game_details"`
- [x] Verify: 15 games for Apr 10-11

### Stream B: core_teams.sql

- [x] Create `pipeline/assets/03_core/core_teams.sql`
- [x] Select from `clean.teams` with final column types and descriptions
- [x] Run: `bruin run pipeline --selector "file:core_teams"`
- [x] Verify: 30 teams, matches clean layer

### Stream C: core_players.sql

- [x] Create `pipeline/assets/03_core/core_players.sql`
- [x] Select from `clean.players` with final column types
- [x] Run: `bruin run pipeline --selector "file:core_players"`
- [x] Verify: 5103 players, matches clean layer

### Stream D: core_games.sql

- [x] Create `pipeline/assets/03_core/core_games.sql`
- [x] Select from `prep.game_details` with final column types
- [x] Run: `bruin run pipeline --selector "file:core_games"`
- [x] Verify: 15 games, no duplicates on re-run

### Stream E: core_game_stats.sql

- [x] Create `pipeline/assets/03_core/core_game_stats.sql`
- [x] Select from `clean.box_scores` with standardized stat column types
- [x] Add player/team names via join with `clean.players` and `clean.teams` for enriched metadata
- [x] Run: `bruin run pipeline --selector "file:core_game_stats"`
- [x] Verify: 401 player-game records, matches clean layer count

## SPRINT 4: Integration, Testing, Polish

### Stream A: Full pipeline run

- [x] Run full pipeline: `bruin run pipeline --workers 1` (13 assets, all pass)
- [x] Verify all tables exist across clean/prep/core layers
- [x] Verify execution order: raw → clean → prep → core
- [x] Test incremental: run with new date range, verify appended without overwriting

### Stream B: AGENTS.md + .gitignore

- [x] Update `AGENTS.md` with 4-layer architecture documentation
- [x] Create `.gitignore` excluding: `nba.duckdb`, `__pycache__/`, `.venv/`
- [x] Verify: `nba.duckdb` is not tracked by git
- [x] Verify: `pull_data.py` and `data/` remain untouched

## Summary

### Sprint Overview

| Sprint | Name | Tasks | Streams |
|--------|------|-------|---------|
| 1 | Foundation | 13 | A, B, C |
| 2 | Clean Layer | 16 | A, B, C, D |
| 3 | Prep + Core | 18 | A, B, C, D, E |
| 4 | Integration, Testing, Polish | 8 | A, B |

### Total Effort

- SPRINTS: 4
- STREAMS: 14
- Tasks: 55

## Notes

- 5-layer structure: `pipeline/assets/{00_load,01_clean,02_prep,03_core,04_mart}/`
- Clean assets are Python (API ingestion), Prep/Core are SQL (transformations)
- `clean_games_raw` outputs team-game grain (one row per team per game)
- `prep_game_details` pivots to game-level grain (home/away on same row)
- `clean_box_scores_raw` fetches game IDs from API, not DuckDB (avoids layer dependency)
- Box score API is slow — expect ~30 seconds per 10 games
- Date range defaults are small (7 days) to avoid long initial runs
- `BRUIN_VARS` env var is JSON — parse with `json.loads(os.environ["BRUIN_VARS"])`
- `--var` values need quotes for strings: `--var 'start_date="2025-10-21"'`

### Quality Standards

- No placeholders — all assets fully functional when marked complete
- Each asset runs independently via `bruin run pipeline --selector "file:<name>"`
- Full pipeline runs end-to-end without manual intervention
- Re-runs with same date params do not create duplicates
