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
│       ├── 00_ingest/      # Python: NBA API calls → raw tables in DuckDB
│       │   ├── raw__teams.py
│       │   ├── raw__players.py
│       │   ├── raw__games.py
│       │   └── raw__box_scores.py
│       ├── 01_clean/       # Layer 1: Standardize types, parse JSON, no joins
│       │   ├── clean__teams.sql
│       │   ├── clean__players.sql
│       │   ├── clean__games.sql
│       │   └── clean__box_scores.sql
│       ├── 02_prep/        # Layer 2: Joins, flattening, business logic
│       │   └── prep__game_details.sql
│       ├── 03_core/        # Layer 3: SSOT entities (atomic granularity)
│       │   ├── core__teams.sql
│       │   ├── core__players.sql
│       │   ├── core__games.sql
│       │   └── core__game_stats.sql
│       └── 04_mart/        # Layer 4: Dashboard-ready datasets
│           └── (future DAC dashboards)
├── nba.duckdb              # Local DuckDB file (gitignored)
├── data/                   # Legacy CSVs from Marimo notebook
└── pull_data.py            # Legacy Marimo notebook (do not modify)
```

## Data Model Layers (Clean → Prep → Core → Mart)

4-layer transformation architecture. Full guidance available via the `layered-modeling` skill (auto-loads on keywords: clean, prep, core, mart, model, transform, SSOT, grain, daisy-chain).

| Layer | Purpose | Naming | Example |
|-------|---------|--------|---------|
| **raw** | Mirror API response as-is (Python ingestion) | `raw.raw_{entity}` | `raw.raw_teams`, `raw.raw_games` |
| **clean** | Standardize types, parse JSON, no joins | `clean__{entity}` | `clean__teams`, `clean__box_scores` |
| **prep** | Flatten, join, deduplicate, normalize | `prep__{description}` | `prep__game_details` |
| **core** | SSOT entities at atomic granularity; no daisy-chaining | `core__{entity}` | `core__teams`, `core__game_stats` |
| **mart** | Dashboard-ready, consumer-shaped datasets | `mart__{use_case}` | (future) |

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

## Naming Convention

File and DuckDB table names use `__` (double underscore) to separate the layer prefix from entity:
- **File**: `raw__teams.py`, `clean__teams.sql`, `prep__game_details.sql`, `core__game_stats.sql`
- **DuckDB**: `raw.teams`, `clean__teams`, `prep__game_details`, `core__game_stats`

Exception: raw layer uses `raw.raw_{entity}` (schema+table prefix) in DuckDB because Bruin's `ingestr` engine requires `<schema>.<table>` format. Filenames still use `__`: `raw__teams.py`.

- **Python assets**: Used for API ingestion (nba_api calls) — live in `load/`
- **SQL assets**: Used for transformations/models — live in `clean/`, `prep/`, `core/`, `mart/`
- All assets live under `pipeline/assets/`
