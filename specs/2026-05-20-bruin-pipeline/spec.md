# Bruin NBA Data Pipeline - Specification

## Overview

Migrate NBA data ingestion from the existing Marimo notebook (`pull_data.py`) to a Bruin pipeline targeting DuckDB. Pipeline runs ad-hoc locally, parameterized by date range, with incremental loading. Dashboard-as-Code (DAC) is deferred to a later phase.

## Requirements

### Functional Requirements

- Ingest NBA teams, players, games, and player box score stats via `nba_api`
- Load all data into a local DuckDB database
- Pipeline parameterized by start/end date (small date chunks, not full season)
- Incremental loading — only fetches data for the specified date range
- Each entity (teams, players, games, game_stats) loaded as separate table
- Executed via `bruin run` from terminal

### Non-Functional Requirements

- Local execution only, no scheduling or automation
- Rate-limit aware (respect NBA API delays between requests)
- Reproducible runs with same date params

## Scope

### In Scope

- Bruin project initialization with DuckDB connection
- Python assets for data ingestion (teams, players, games, box scores)
- Date range parameters on the pipeline
- `uv` for Python dependency management
- Incremental load logic based on date params

### Out of Scope

- Deleting or modifying the existing Marimo notebook
- Dashboard creation (DAC)
- Automated scheduling or CI/CD
- Data modeling / transformations beyond initial ingestion
- Expanding data sources beyond current NBA API endpoints

## Approach

### Technical Approach

- Initialize Bruin project with `.bruin.yml` configuring a DuckDB connection
- Use Bruin Python assets (run via `uv`) for ingestion:
  - `ingest_teams.py` — static data, full refresh
  - `ingest_players.py` — static data, full refresh
  - `ingest_games.py` — parameterized by date range, incremental
  - `ingest_box_scores.py` — parameterized by date range, incremental, with rate-limit delays
- Date parameters defined as Bruin `variables` in `pipeline.yml` with sensible defaults (e.g., last 7 days)
- Override at runtime via `bruin run --var start_date=2025-10-01 --var end_date=2025-10-31`
- DuckDB file stored locally in project (e.g., `nba.duckdb`)
- Tables: `teams`, `players`, `games`, `game_stats`

### User Experience

- User runs `bruin run` (uses defaults) or `bruin run --var start_date=2025-10-01 --var end_date=2025-10-31`
- Progress visible in terminal output
- Data queryable in DuckDB after run completes

## Dependencies

- `bruin` CLI installed
- `uv` installed
- `nba_api` Python package
- `pandas` Python package
- DuckDB (via Python driver)

## Success Criteria

- `bruin run` completes successfully with a given date range
- All four tables populated in DuckDB with correct data
- Re-running with same params does not create duplicates
- Re-running with new date range appends only new data
- Marimo notebook remains untouched

## Notes

- NBA API has rate limits — box score ingestion needs `time.sleep()` between requests
- Teams and players are essentially static; can use REPLACE strategy
- Games and game_stats are time-series; use incremental append with deduplication
- DAC dashboards planned as follow-up phase once pipeline is stable
