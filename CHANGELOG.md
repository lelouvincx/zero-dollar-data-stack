# Changelog

## [Unreleased]

### Changed

- Rename the anfra app to zero-dollar-data-stack-github-health so it doesn't collide with later projects. [#3](https://github.com/lelouvincx/zero-dollar-data-stack/pull/3)
- Model authors as a dimension: new dim_authors, facts keyed by author_id, and repo stars read from fct_repo_snapshots. [#2](https://github.com/lelouvincx/zero-dollar-data-stack/pull/2)
- Split the daily refresh workflow into sequential ingest and transform jobs. [#1](https://github.com/lelouvincx/zero-dollar-data-stack/pull/1)
- Shorten README, move infrastructure tests into .agents/tests, remove the PR template and document agent-controlled merging. [#2](https://github.com/lelouvincx/template/pull/2)
- Add shared agent lifecycle hooks, bounded personal Amp configuration, generated-copy regressions and read-only shell CI. [#1](https://github.com/lelouvincx/template/pull/1)
<!-- Add linked entries after opening each pull request. -->
