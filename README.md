# NBA Data Pipeline

A little side project to kick the tires on [Bruin](https://getbruin.com/) — an open-source data pipeline framework — while poking around NBA game data for fun. Nothing production-grade, just a playground.

## What it does

Pulls data from the [NBA API](https://github.com/swar/nba_api) (teams, players, games, box scores, play-by-play) into a local DuckDB database, then runs a few SQL transformations to clean things up and make the data queryable.

## Tech stack

| Thing | Why |
|---|---|
| **[Bruin](https://getbruin.com/)** | Pipeline orchestration — wanted to try it |
| **[DuckDB](https://duckdb.org/)** | Local analytics database, zero setup |
| **[nba_api](https://github.com/swar/nba_api)** | Python wrapper for stats.nba.com |
| **[uv](https://docs.astral.sh/uv/)** | Python package management |
| **[Altair](https://altair-viz.github.io/)** | Quick charts (Marimo notebook) |

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
```

## How it's wired up

Data flows through a few layers:

1. **Ingest** (Python) — NBA API calls → month-partitioned Parquet files
2. **Clean** (SQL) — Standardize types, parse JSON blobs, no joins
3. **Prep** (SQL) — Flatten, join, and deduplicate
4. **Mart** (SQL) — Dashboard-friendly views (one exists so far)

Params like `start_date` / `end_date` get passed through the pipeline for incremental loads.

## Why this exists

Honest answer: wanted a real-ish dataset to test Bruin with. NBA data is fun, the API is decent, and DuckDB makes everything fast on a laptop. Plus it's a good excuse to look at basketball stats.
