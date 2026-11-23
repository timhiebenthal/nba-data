# NBA Data Pipeline

A personal project for exploring NBA data with [Bruin](https://getbruin.com/) and DuckDB.

## What it does

Pulls data from the [NBA API](https://github.com/swar/nba_api) (teams, players, games, box scores, play-by-play) into a local DuckDB database, then runs a few SQL transformations to clean things up and make the data queryable.

## Tech stack

| Thing | Why |
|---|---|
| **[Bruin](https://getbruin.com/)** | Pipeline orchestration |
| **[DuckDB](https://duckdb.org/)** | Local analytics database, zero setup |
| **[nba_api](https://github.com/swar/nba_api)** | Python wrapper for stats.nba.com |
| **[uv](https://docs.astral.sh/uv/)** | Python package management |
| **[Altair](https://altair-viz.github.io/)** | Visualizations in the Marimo notebook |
| **Trellis** | Visual data model editor |

## Quick start

```bash
# Install deps + pre-commit hooks
make init

# Fetch NBA data for a date range → transform it into DuckDB tables
make run

# Or fetch a specific range
bruin run pipeline --var 'start_date="2025-10-21"' --var 'end_date="2025-11-01"'

# Poke around the data
make query

# Explore the notebook or data model
make marimo
uv run trellis run
```

## How it's wired up

Data flows through a few layers:

1. **Ingest** (Python) — NBA API calls → month-partitioned Parquet files
2. **Clean** (SQL) — Standardize types, parse JSON blobs, no joins
3. **Prep** (SQL) — Flatten, join, and deduplicate
4. **Core** (SQL) — Dimensional tables for games, players, teams, actions, and play-by-play
5. **Mart** (SQL) — Dashboard-ready game and play-by-play datasets

Params like `start_date` / `end_date` get passed through the pipeline for incremental loads.

## Why this exists

The project is a playground for building a local data pipeline and exploring basketball statistics.
