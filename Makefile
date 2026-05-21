.PHONY: init run run-dates query ui status clean-db

START ?= "2026-04-01"
END ?= "2026-05-20"

export PATH := /home/tim_ubuntu/.local/bin:$(PATH)

init:
	@echo "Installing Python dependencies with uv..."
	uv sync
	@echo "Validating Bruin pipeline..."
	bruin validate

run:
	bruin run pipeline

run-dates:
	bruin run pipeline --var start_date=$(START) --var end_date=$(END)

query:
	duckdb nba.duckdb

ui:
	duckdb --ui nba.duckdb

status:
	bruin validate

clean-db:
	rm -f nba.duckdb
