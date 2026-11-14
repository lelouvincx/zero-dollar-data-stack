# The zero-dollar data stack

A free modern data stack, end to end: GitHub activity of the data tools themselves goes from the GitHub API to a shared dashboard for $0 a month.

![Architecture of a free modern data stack: dlt loads GitHub activity into DuckDB, dbt models it, anfra defines the metrics as code and serves the dashboard, and GitHub Actions runs the first three steps daily](https://media.secondbrain.lelouvincx.com/2026/11/aad8de773a4572003e15498720a25efc.gif)

| Layer | Tool | Where |
| --- | --- | --- |
| Ingestion | [dlt](https://dlthub.com/) | `ingest/` |
| Storage | [DuckDB](https://duckdb.org/) locally, [MotherDuck](https://motherduck.com/) to share | `data/` |
| Transformation | [dbt Core](https://github.com/dbt-labs/dbt) | `transform/` |
| Orchestration | GitHub Actions | `.github/workflows/refresh.yml` |
| Semantic layer and BI | [anfra](https://anfra.ai/?utm_source=github&utm_medium=readme&utm_campaign=zero-dollar-stack) | `anfra/` |

The write-up: [The zero-dollar data stack](https://lelouvincx.com/) on lelouvincx.com.

## Run it

You need [uv](https://docs.astral.sh/uv/), [anfra](https://anfra.ai/docs), and a GitHub token for the API rate limit.

```sh
make install
GITHUB_TOKEN=$(gh auth token) make ingest   # about 10 minutes for 12 months of data
make transform                              # dbt seed + build, with tests
make serve                                  # anfra serve: open http://127.0.0.1:7878/
```

Everything lands in `data/github.duckdb`. No account needed.

## Tracked tools

dlt, DuckDB, dbt, SQLMesh, anfra, Cube, Evidence, Metabase and Superset.

Want another tool tracked? Add it to `REPOS` in [`ingest/github_pipeline.py`](ingest/github_pipeline.py) and its layer to [`transform/seeds/tool_layers.csv`](transform/seeds/tool_layers.csv), then submit a PR!

## Metrics

Defined once in [`anfra/datasets/github_health.dataset.aml`](anfra/datasets/github_health.dataset.aml):

- **Median first response (hours):** how fast a maintainer replies to an issue from the community
- **Issues answered by a maintainer:** the share of community issues that got a maintainer reply
- **Community PR share:** the share of merged pull requests from outside the core team, bots excluded
- **Median time to merge**, **releases**, **issues** and **pull requests opened**, and **stars**

"Core team" means anyone who merged a pull request in the repo, or whom GitHub shows as an owner, member or collaborator. Merging catches engineers whose org membership is private, whom GitHub labels as contributors. Bots are GitHub Apps and `*[bot]`, `*-bot` or `*automation*` logins.

## Known limits

- Only issues and pull requests opened in the last 365 days count.
- First responses are read from an issue's first 10 comments; a later first reply counts as no reply.
- Stars are a snapshot per run, so star history starts the day the pipeline first ran.
