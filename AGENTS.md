# NBA Data Pipeline — Agent Guide

## Project Overview

Ad-hoc NBA data ingestion pipeline using Bruin + DuckDB. Pulls data from the NBA API (teams, players, games, box scores) into local DuckDB tables. Parameterized by date range for incremental loads.

## Tech Stack

| Layer | Tool |
|-------|------|
| Pipeline orchestration | Bruin |
| Data store | DuckDB (local file) |
| Ingestion language | Python |
| Package manager | uv |
| Source API | nba_api |
| Dashboards (future) | DAC (Bruin Dashboard-as-Code) |

## Project Structure

```
nba-data/
├── .bruin.yml              # Bruin project config + connections
├── Makefile                # Common commands
├── AGENTS.md               # This file
├── pipeline/
│   ├── pipeline.yml        # Pipeline definition + variables
│   └── assets/
│       ├── 00_load/        # Python: NBA API calls → raw tables in DuckDB
│       │   ├── load_teams.py
│       │   ├── load_players.py
│       │   ├── load_games.py
│       │   └── load_box_scores.py
│       ├── 01_clean/       # Layer 1: Standardize types, parse JSON, no joins
│       │   ├── clean_teams.sql
│       │   ├── clean_players.sql
│       │   ├── clean_games.sql
│       │   └── clean_box_scores.sql
│       ├── 02_prep/        # Layer 2: Joins, flattening, business logic
│       │   └── prep_game_details.sql
│       ├── 03_core/        # Layer 3: SSOT entities (atomic granularity)
│       │   ├── core_teams.sql
│       │   ├── core_players.sql
│       │   ├── core_games.sql
│       │   └── core_game_stats.sql
│       └── 04_mart/        # Layer 4: Dashboard-ready datasets
│           └── (future DAC dashboards)
├── nba.duckdb              # Local DuckDB file (gitignored)
├── data/                   # Legacy CSVs from Marimo notebook
└── pull_data.py            # Legacy Marimo notebook (do not modify)
```

## Data Model Layers (Clean → Prep → Core → Mart)

4-layer transformation architecture. Full guidance available via the `layered-modeling` skill (auto-loads on keywords: clean, prep, core, mart, model, transform, SSOT, grain, daisy-chain).

| Layer | Purpose | Naming |
|-------|---------|--------|
| **clean** | Mirror raw API into structured tables; no joins | `clean_{source}_{entity}` |
| **prep** | Flatten, join, deduplicate, normalize | `prep_{description}` |
| **core** | SSOT entities at atomic granularity; no daisy-chaining | `core_{entity}` |
| **mart** | Dashboard-ready, consumer-shaped datasets | `mart_{use_case}` |

## Common Commands

```bash
make init        # Initialize Bruin project + install deps
make run         # Run full pipeline (uses default date range)
make query       # Open DuckDB REPL for ad-hoc queries
make status      # Show pipeline asset status
make clean-db    # Remove DuckDB file (start fresh)
```

## Key Conventions

- Python assets run via `uv` — dependencies declared in each asset's header or `pyproject.toml`
- Date parameters: `start_date` and `end_date` as Bruin variables in `pipeline.yml`, overridden via `--var`
- Incremental loads: games and box scores append by date range; teams/players use replace
- Rate limits: box score ingestion includes `time.sleep(2.5)` between API calls
- Marimo notebook (`pull_data.py`) is legacy — do not modify or delete
- `--var` values need quotes for strings: `--var 'start_date="2025-10-21"'`

## Bruin Asset Types

- **Python assets**: Used for API ingestion (nba_api calls) — live in `load/`
- **SQL assets**: Used for transformations/models — live in `clean/`, `prep/`, `core/`, `mart/`
- All assets live under `pipeline/assets/`
