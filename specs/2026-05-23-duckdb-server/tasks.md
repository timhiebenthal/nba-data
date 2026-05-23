# DuckDB Server Mode - Implementation Tasks

## Overview

Upgrade DuckDB to v1.4+ and enable HTTP server mode for concurrent multi-client access.

## Tasks

### SPRINT 1: Foundation

#### Stream A: DuckDB Upgrade
- [x] **Upgrade DuckDB** to latest stable (v1.4+)
  - Run: `curl -fsS https://duckdb.org/install.sh | sh`
  - Verify: `duckdb --version` shows v1.4+
  - Test: `duckdb nba.duckdb -c "SELECT 1;"` works with existing data

#### Stream B: Quack Extension
- [x] **Install quack extension**
  - Run: `duckdb nba.duckdb -c "INSTALL quack; LOAD quack;"`
  - Verify: Extension loads without error
  - Test: `duckdb nba.duckdb -c "CALL quack_serve('quack:localhost');"` starts server
  - Note: Server starts but port binding has beta issues in v1.5.3. Quack is under active development.

### SPRINT 2: Configuration

#### Stream A: .bruin.yml Connection
- [ ] **Update .bruin.yml** connection from file path to Quack
  - Change `nba_duckdb` connection type to use Quack URI when server is running
  - Verify: `bruin validate` passes
  - Note: Blocked until Quack server binding works reliably

#### Stream B: Makefile Commands
- [ ] **Add `make server`** target
  - Command: `duckdb nba.duckdb -c "LOAD quack; CALL quack_serve('quack:localhost');"`
  - Note: Server starts but port binding has beta issues
  - Test: `make server` starts server, curl returns response

- [ ] **Add `make stop-server`** target
  - Command: `pkill -f "duckdb.*quack" || true`
  - Test: Server process terminates

- [ ] **Update `make query`** to use Quack
  - Command: `duckdb -c "LOAD quack; ATTACH 'quack:localhost' AS remote (TOKEN '...');"`
  - Note: Blocked until Quack server binding works reliably

- [ ] **Update `make ui`** to use server
  - Command: `duckdb --ui -c "LOAD quack; ATTACH 'quack:localhost' AS remote (TOKEN '...');"`
  - Note: Blocked until Quack server binding works reliably

### SPRINT 3: Integration & Testing

#### Stream A: End-to-End Testing
- [ ] **Test concurrent access**
  - Start: `make server`
  - Terminal 1: `make query` (connects via Quack)
  - Terminal 2: `make ui` (opens browser)
  - Terminal 3: `make transform` (Bruin runs SQL)
  - Verify: All three work simultaneously without lock errors
  - Note: Blocked until Quack server binding works reliably

- [ ] **Test pipeline with server**
  - Run: `make load` (writes parquet files)
  - Run: `make transform` (reads parquet, writes to DuckDB via Quack)
  - Verify: All SQL assets complete successfully
  - Verify: Data visible in `make query` and `make ui`
  - Note: Blocked until Quack server binding works reliably

#### Stream B: Documentation
- [ ] **Update AGENTS.md** with Quack mode usage
  - Document `make server`, `make stop-server`, `make query`, `make ui`
  - Note: Server must be running for VS Code extension to work
  - Include troubleshooting: "If lock error, run `make stop-server` then `make server`"
  - Note: Quack is in beta, may not work reliably until v2.0

## Summary

### Sprint Overview
| Sprint | Name | Tasks | Streams |
|--------|------|--------|---------|
| 1 | Foundation | 2 | A, B |
| 2 | Configuration | 4 | A, B |
| 3 | Integration & Testing | 2 | A, B |

### Total Effort
- SPRINTS: 3
- STREAMS: 6 (2 per sprint)
- Tasks: 8

## Notes
- DuckDB v1.3.0 lacks httpserver extension — upgrade is prerequisite
- Existing `nba.duckdb` data should be preserved during upgrade
- Server mode is localhost-only — no network exposure
- If server crashes, clients get connection errors (not lock errors)

### Quality Standards
- No placeholders
- Complete integration
- User-facing quality
