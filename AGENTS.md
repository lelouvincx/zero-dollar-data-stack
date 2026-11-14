# Project instructions

- Keep shared agent infrastructure in `lelouvincx/agent-skills`. Run `.agents/sync` after changing runtime customizations.
- Bootstrap with `.agents/setup`; set an absolute `AGENT_SKILLS_DIR` if shared source is outside the standard Orb paths or a sibling checkout.
- Put project customizations and application lifecycle work in `.agents/project`. Keep sync free of application work.
- Run `bash .agents/tests/lifecycle.sh` and `bash .agents/tests/configure-amp.sh` before delivery. Add stack-specific checks when the project gains application code.
- Use conventional branches and commits.
- For shipping, load `shipping-personal-projects` and preserve project-specific release gates. Use the approved bot publisher. Stop if authorization or the approved publishing path is unavailable.
- Add a linked `CHANGELOG.md` entry after opening each pull request, in a separate commit.
- The agent merges only after current-head CI passes and the linked changelog entry is verified. There is no auto-merge workflow.
- Amp configuration: run `.agents/configure-amp` only when requested, with jq and an authenticated Amp CLI. Confirm `origin` identifies the generated `lelouvincx` repository. Bot access and publishing-policy approval are separate prerequisites.
- Amp readback omits Ship and additional repositories; the local apply receipt does not prove their remote state. To reapply after hidden drift, unset only `agentInfrastructure.ampReceipt` in local Git config and rerun configuration; preserve `agentInfrastructure.ampProjectID` for recovery.
- Keep secrets in 1Password. Local env files contain `op://` references only; resolve secrets at execution time.
- Store transient evidence under `.amp/in/artifacts/`. Preserve unrelated work and runtime files.

## This project

- Stack: dlt (`ingest/`) → DuckDB `data/github.duckdb` → dbt (`transform/`) → anfra (`anfra/`). Run with `make ingest transform`, then `make serve`.
- Python runs through `uv`. dbt runs from the repo root through `make transform`, with `transform/profiles.yml`.
- Metrics live in `anfra/datasets/github_health.dataset.aml`. Change them there, never inside an app. Run `make validate` after any AML change.
- A new tracked repo needs both `REPOS` in `ingest/github_pipeline.py` and a row in `transform/seeds/tool_layers.csv`.
- The daily workflow writes to MotherDuck and needs the `MOTHERDUCK_TOKEN` repo secret.
