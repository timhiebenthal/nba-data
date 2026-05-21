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

Following the 4-layer transformation architecture. Each layer has a single responsibility and strict boundaries.

### Layer Overview

| Layer | Purpose | Upstream | Downstream | Naming |
|-------|---------|----------|------------|--------|
| **clean** | Mirror raw API into structured tables | Raw API responses | prep | `clean_{source}_{entity}` |
| **prep** | Flatten, join, deduplicate, normalize | clean | core | `prep_{description}` |
| **core** | SSOT entities at atomic granularity | prep (or clean for simple cases) | mart | `core_{entity}` |
| **mart** | Dashboard-ready, consumer-shaped datasets | core | BI / DAC | `mart_{use_case}` |

### Layer 1: Clean

**What it does:**
- Call the source API (Python) or parse raw JSON/CSV into columns
- Standardize types: cast timestamps, booleans, numeric types
- Rename columns to snake_case
- Handle nulls from the source (don't invent defaults)

**What it does NOT do:**
- No joins between sources
- No business logic or derived columns
- No deduplication (pass through duplicates as-is)
- No filtering rows (except source-level pagination)

**Anti-patterns:**
- `CASE WHEN` logic for business rules → move to prep
- `JOIN` to another clean table → move to prep
- `WHERE` clauses that drop data → move to prep or core

### Layer 2: Prep

**What it does:**
- Flatten nested/JSON arrays into rows (unnest, explode)
- Join clean tables to resolve foreign keys (e.g. `team_id` → team name)
- Deduplicate records (window functions, `ROW_NUMBER()`)
- Parse and split compound columns
- Create intermediate derived columns needed by core

**What it does NOT do:**
- No aggregations that define a metric (that's core or mart)
- No final SSOT logic (that's core)
- No dashboard-specific shaping (that's mart)

**Anti-patterns:**
- Aggregating to game-level stats → belongs in core
- Pivoting for a specific chart → belongs in mart
- Daisy-chaining: prep → prep → prep (keep to one prep step when possible)

### Layer 3: Core

**What it does:**
- One table per business entity (teams, players, games, game_stats)
- Atomic grain: one row = one thing at one point in time
- Apply SSOT rules: deduplicate, resolve conflicts, pick latest
- Define canonical metrics at their natural grain
- Add business key columns and consistent naming

**What it does NOT do:**
- No joins between core tables (daisy-chaining forbidden)
- No pre-aggregation for dashboards (that's mart)
- No consumer-specific columns (that's mart)

**Anti-patterns:**
- `core_games` JOIN `core_players` → each is its own SSOT
- `SUM()` across games for a season total → belongs in mart
- Adding a "is_playoff_game" flag that only one dashboard needs → belongs in mart

**Core table rules:**
1. Each core table is independently queryable and meaningful
2. Grain must be documented (e.g. "one row per player per game")
3. Never reference another core table in a FROM or JOIN
4. If you need data from two sources, join in prep, not core

### Layer 4: Mart

**What it does:**
- Shape data for a specific consumer (dashboard, report, API)
- Pre-aggregate metrics (season averages, rolling stats)
- Denormalize for query performance
- Add presentation-layer columns (formatted strings, rankings)

**What it does NOT do:**
- No new business logic (all logic lives in prep or core)
- No raw data access (only reads from core)
- No cross-mart dependencies

**Anti-patterns:**
- Mart reading from another mart → always read from core
- Mart containing logic that should be a core metric → move to core
- One mart trying to serve 5 different dashboards → split into separate marts

### Decision Flow: Where does logic go?

```
Is it a raw API call or type cast?
  → clean

Is it flattening JSON, joining sources, or deduplicating?
  → prep

Is it defining the canonical version of an entity or metric?
  → core

Is it shaping data for a specific dashboard or report?
  → mart
```

### Layer Rules Summary
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

- **Python assets**: Used for API ingestion (nba_api calls) — live in `load/`
- **SQL assets**: Used for transformations/models — live in `clean/`, `prep/`, `core/`, `mart/`
- All assets live under `pipeline/assets/`
