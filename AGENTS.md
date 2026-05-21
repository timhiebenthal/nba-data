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
│       ├── clean/          # Layer 1: Raw ingestion from NBA API
│       │   ├── clean_teams.py
│       │   ├── clean_players.py
│       │   ├── clean_games_raw.py
│       │   └── clean_box_scores_raw.py
│       ├── prep/           # Layer 2: Joins, flattening, business logic
│       │   └── prep_game_details.sql
│       ├── core/           # Layer 3: SSOT entities (atomic granularity)
│       │   ├── core_teams.sql
│       │   ├── core_players.sql
│       │   ├── core_games.sql
│       │   └── core_game_stats.sql
│       └── mart/           # Layer 4: Dashboard-ready datasets
│           └── (future DAC dashboards)
├── nba.duckdb              # Local DuckDB file (gitignored)
├── data/                   # Legacy CSVs from Marimo notebook
└── pull_data.py            # Legacy Marimo notebook (do not modify)
```

## Data Model Layers (Clean → Prep → Core → Mart)

Following the 4-layer transformation architecture:

| Layer | Purpose | Assets |
|-------|---------|--------|
| **clean** | One table per raw API response; standardize types, no joins | Python assets calling `nba_api` |
| **prep** | Flatten nested data, join lookups, deduplicate | SQL assets transforming clean tables |
| **core** | SSOT entities at atomic granularity; no daisy-chaining | SQL assets, one per entity (teams, players, games, game_stats) |
| **mart** | Dashboard-ready datasets; pre-aggregated, denormalized | SQL assets or DAC dashboards |

### Layer Rules
- **Clean**: No business logic, no joins. Named `clean_{source}_{entity}`
- **Prep**: Complex transforms live here, not in Core. Named `prep_{description}`
- **Core**: One table per entity. Never daisy-chain core tables. Named `core_{entity}`
- **Mart**: Shape depends on consumer (DAC dashboards). Named `mart_{use_case}`

## Common Commands

```bash
make init        # Initialize Bruin project + install deps
make run         # Run full pipeline (uses default date range)
make run-dates   # Run pipeline with custom dates: make run-dates START=2025-10-01 END=2025-10-31
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

- **Python assets**: Used for API ingestion (nba_api calls) — live in `clean/`
- **SQL assets**: Used for transformations/models — live in `prep/`, `core/`, `mart/`
- All assets live under `pipeline/assets/`
