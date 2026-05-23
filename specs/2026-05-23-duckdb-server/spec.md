# DuckDB Server Mode - Specification

## Overview

Enable DuckDB to run as a persistent HTTP server so multiple clients (Bruin pipeline, VS Code extension, DuckDB CLI, DuckDB UI) can connect simultaneously without file lock conflicts.

Currently, `make ui` holds an exclusive lock on `nba.duckdb`, preventing the Bruin VS Code extension from querying. Error: "Conflicting lock is held."

## Requirements

### Functional Requirements
- DuckDB runs as a persistent server process accessible via HTTP
- Multiple clients can query simultaneously (read + write)
- Bruin pipeline connects via HTTP instead of file path
- VS Code extension connects via HTTP
- DuckDB CLI can connect via HTTP for ad-hoc queries
- DuckDB UI accessible via browser

### Non-Functional Requirements
- Server starts/stops cleanly via Makefile commands
- No data loss when switching from file mode to server mode
- Server auto-reconnects on client disconnect
- Minimal configuration changes to existing pipeline

## Scope

### In Scope
- Upgrade DuckDB from v1.3.0 to v1.4+ (required for httpserver extension)
- `.bruin.yml` connection change from file path to HTTP
- Makefile additions: `make server`, updated `make query`, `make ui`
- DuckDB server startup with `nba.duckdb` as persistent database
- Documentation in AGENTS.md

### Out of Scope
- DuckDB Quack project (separate, more advanced)
- Authentication/authorization for server
- Network exposure beyond localhost
- Production-grade HA/failover

## Approach

### Technical Approach
- **Prerequisite**: Upgrade DuckDB from v1.3.0 to v1.5.3 (completed)
- Install `quack` extension: `INSTALL quack; LOAD quack;`
- Start server: `duckdb nba.duckdb -c "LOAD quack; CALL quack_serve('quack:localhost');"`
- Server listens on `localhost:9494` by default
- Change `.bruin.yml` connection from local file to Quack URI
- Clients connect via `ATTACH 'quack:localhost' AS remote (TOKEN '...')`

**Note**: Quack is in beta (released May 12, 2026). Server binding may have issues in v1.5.3. Alternative: use DuckDB's built-in concurrent read support (multiple readers allowed, writes serialized).

### Configuration Changes
- `.bruin.yml`: connection `nba_duckdb` changes from file path to `duckdb://localhost:7867`
- `Makefile`: add `server`, `stop-server` targets
- `Makefile`: update `query`, `ui` to use HTTP connection
- `pyproject.toml`: update duckdb version requirement

### User Experience
- `make server` — starts DuckDB server in background
- `make query` — connects via HTTP CLI
- `make ui` — opens DuckDB UI in browser (server already running)
- VS Code extension works simultaneously with server running
- `make stop-server` — clean shutdown

## Dependencies
- DuckDB v1.4+ (upgrade from current v1.3.0)
- `httpserver` extension (available in v1.4+)
- No external packages needed

## Success Criteria
- `make ui` + VS Code extension can query simultaneously
- `make load` and `make transform` work with server connection
- No file lock errors
- Server starts/stops cleanly via Makefile
- Existing data in `nba.duckdb` preserved after upgrade

## Notes
- DuckDB v1.3.0 does NOT support httpserver extension (404 on download)
- Latest DuckDB is v1.5.3 as of May 2026
- Server persists data to `nba.duckdb` file on disk
- Only localhost access — no network exposure risk
- If server is not running, clients fall back to file mode (with lock)
- **Quack is in beta** (released May 12, 2026) — server binding has known issues in v1.5.3
- Alternative: DuckDB supports concurrent reads natively; lock issue is write-only
- Quack will be stable in DuckDB v2.0 (expected late 2026)
