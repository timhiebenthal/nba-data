.PHONY: init run query ui status clean-db format-sql install-hooks

export PATH := /home/tim_ubuntu/.local/bin:$(PATH)

init: install-hooks
	@echo "Validating Bruin pipeline..."
	bruin validate

install-hooks:
	@echo "Installing Python dependencies with uv..."
	uv sync
	@echo "Installing pre-commit hooks..."
	uv run pre-commit install

run:
	bruin run pipeline

load:
	bruin run pipeline --selector "fqn:*raw*"

transform:
	bruin run pipeline --selector "path:assets/01_clean+"

test:
	bruin run pipeline --only checks

query:
	duckdb nba.duckdb

ui:
	duckdb --ui nba.duckdb

status:
	bruin validate

clean-db:
	rm -f nba.duckdb

clean-raw:
	rm -rf data/raw/*/

format-sql:
	uv run sqlfmt pipeline/assets

marimo:
	uv run marimo edit notebook.py