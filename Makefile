.PHONY: init run query ui status clean-db

export PATH := /home/tim_ubuntu/.local/bin:$(PATH)

init:
	@echo "Installing Python dependencies with uv..."
	uv sync
	@echo "Validating Bruin pipeline..."
	bruin validate

run:
	bruin run pipeline

query:
	duckdb nba.duckdb

ui:
	duckdb --ui nba.duckdb

status:
	bruin validate

clean-db:
	rm -f nba.duckdb
