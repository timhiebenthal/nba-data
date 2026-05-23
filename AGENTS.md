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
│       ├── 00_ingest/      # Python: NBA API calls → raw parquet files
│       │   ├── raw__teams.py
│       │   ├── raw__players.py
│       │   ├── raw__games.py
│       │   ├── raw__box_scores.py
│       │   └── raw__play_by_play.py
│       ├── 01_clean/       # Layer 1: Standardize types, parse JSON, no joins
│       │   ├── clean__teams.sql
│       │   ├── clean__players.sql
│       │   ├── clean__games.sql
│       │   ├── clean__box_scores.sql
│       │   └── clean__play_by_play.sql
│       ├── 02_prep/        # Layer 2: Joins, flattening, business logic
│       │   ├── prep__game.sql
│       │   ├── prep__play_by_play.sql
│       │   ├── prep__player.sql
│       │   └── prep__team.sql
│       ├── 03_core/        # Layer 3: SSOT entities (atomic granularity)
│       │   └── (future)
│       └── 04_mart/        # Layer 4: Dashboard-ready datasets
│           ├── mart__player_season_stats.sql
│           ├── mart__team_standings.sql
│           └── mart__game_summaries.sql
├── nba.duckdb              # Local DuckDB file (gitignored)
├── data/                   # Legacy CSVs from Marimo notebook
└── pull_data.py            # Legacy Marimo notebook (do not modify)
```

## Data Model Layers (Clean → Prep → Core → Mart)

4-layer transformation architecture. Full guidance available via the `layered-modeling` skill (auto-loads on keywords: clean, prep, core, mart, model, transform, SSOT, grain, daisy-chain).

| Layer | Purpose | Naming | Example |
|-------|---------|--------|---------|
| **raw** | Mirror API response as-is (Python → parquet) | `raw.raw_{entity}` | `raw.raw_teams`, `raw.raw_games` |
| **clean** | Standardize types, parse JSON, no joins | `clean.clean__{entity}` | `clean.clean__box_scores` |
| **prep** | Flatten, join, deduplicate, normalize | `prep.prep__{description}` | `prep.prep__game_details` |
| **core** | SSOT entities at atomic granularity; no daisy-chaining | `core.core__{entity}` | `core.core__game_stats` |
| **mart** | Dashboard-ready, consumer-shaped datasets | `mart.mart__{use_case}` | `mart.mart__player_season_stats` |

## Common Commands

```bash
make init        # Initialize Bruin project + install deps
make run         # Run full pipeline (uses default date range)
make load        # Run only raw Python assets (fetch NBA API → parquet)
make transform   # Run only SQL assets (parquet → DuckDB tables)
make query       # Open DuckDB REPL for ad-hoc queries
make status      # Show pipeline asset status
make clean-db    # Remove DuckDB file (start fresh)
make clean-raw   # Remove all parquet files in data/raw/
make format-sql  # Format pipeline SQL with sqlfmt
make install-hooks # uv sync + pre-commit (sqlfmt on commit)
```

## Testing Changes

Always verify before telling the user things work. No `--dry-run` flag exists in Bruin.

```bash
# 1. Validate syntax (instant)
bruin validate

# 2. Check selector matches the right assets (instant)
bruin run pipeline --selector "path:assets/01_clean+"
# → Look for "Running selected assets: ..." in output

# 3. Quick end-to-end with small date range (2-3 min)
bruin run pipeline --var 'start_date="2025-10-21"' --var 'end_date="2025-10-22"'
```

**Rule of thumb:** Always run `bruin validate` and check selector output before committing to a full run. Use a 1–2 day date range for end-to-end tests, not the full season.

SQL assets use [sqlfmt](https://sqlfmt.com) (`shandy-sqlfmt`). A **pre-commit** hook formats `pipeline/assets/**/*.sql` on commit. Run `make format-sql` before committing, or let the hook fix SQL when you commit. Optional: `yassun7010.shandy-sqlfmt` in VS Code for manual **Format Document** only.

## Key Conventions

- Python assets run via `uv` — dependencies declared in each asset's header or `pyproject.toml`
- Date parameters: `start_date` and `end_date` as Bruin variables in `pipeline.yml`, overridden via `--var`
- Incremental loads: games and box scores append by date range; teams/players use replace
- Rate limits: box score ingestion includes `time.sleep(2.5)` between API calls
- Marimo notebook (`pull_data.py`) is legacy — do not modify or delete
- `--var` values need quotes for strings: `--var 'start_date="2025-10-21"'`

## Naming Convention

File names use `__` (double underscore) to separate the layer prefix from entity — same as before.
DuckDB table names use dots: one schema per layer.

| Layer | Schema | File Pattern | DuckDB Table |
|-------|--------|-------------|--------------|
| raw | `raw` | `raw__{entity}.py` | `raw.raw_{entity}` (parquet files, no DuckDB table) |
| clean | `clean` | `clean__{entity}.sql` | `clean.clean__{entity}` |
| prep | `prep` | `prep__{description}.sql` | `prep.prep__{description}` |
| core | `core` | `core__{entity}.sql` | `core.core__{entity}` |
| mart | `mart` | `mart__{use_case}.sql` | `mart.mart__{use_case}` |

Raw Python assets write month-partitioned parquet files to `data/raw/raw__{entity}/YYYY-MM.parquet`.
Clean SQL assets read via `read_parquet('data/raw/raw__{entity}/*.parquet')` glob. This supports
incremental accumulation — each run writes only its months, preserving previous data.
