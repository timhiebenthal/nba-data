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
	bruin run pipeline --workers 1

query:
	duckdb nba.duckdb

ui:
	duckdb --ui nba.duckdb

status:
	bruin validate

clean-db:
	rm -f nba.duckdb

format-sql:
	uv run sqlfmt pipeline/assets
