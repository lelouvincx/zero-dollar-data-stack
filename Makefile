# Locally everything lands in data/github.duckdb. Set TARGET=motherduck (with
# MOTHERDUCK_TOKEN) to write to MotherDuck instead, as the daily workflow does.
TARGET ?= local
DBT_ARGS = --project-dir transform --profiles-dir transform --target $(TARGET)

.PHONY: install ingest transform test serve validate all

install:
	uv sync

ingest:
	DESTINATION=$(if $(filter motherduck,$(TARGET)),motherduck,duckdb) uv run python ingest/github_pipeline.py

transform:
	uv run dbt seed $(DBT_ARGS)
	uv run dbt build $(DBT_ARGS)

validate:
	cd anfra && anfra validate

serve:
	cd anfra && anfra serve

all: ingest transform validate
