"""Load GitHub activity for a list of data tools into DuckDB (or MotherDuck) with dlt.

Tables in the `raw_github` dataset:
- repos: one row per repo per run (a daily snapshot of stars, forks and open issues)
- issues: issues updated in the window, with their first comments nested
- pull_requests: pull requests updated in the window
- releases: releases published in the window

Run:  uv run python ingest/github_pipeline.py
Env:  GITHUB_TOKEN (required), DESTINATION=duckdb|motherduck (default duckdb),
      LOOKBACK_DAYS (default 365), MOTHERDUCK_TOKEN when DESTINATION=motherduck
"""

import os
from datetime import datetime, timedelta, timezone

import dlt
import requests

# Want another tool tracked? Add it here and submit a PR!
REPOS = [
    "dlt-hub/dlt",
    "duckdb/duckdb",
    "dbt-labs/dbt",
    "SQLMesh/sqlmesh",
    "holistics/anfra",
    "cube-js/cube",
    "evidence-dev/evidence",
    "metabase/metabase",
    "apache/superset",
]

GRAPHQL_URL = "https://api.github.com/graphql"
LOOKBACK_DAYS = int(os.environ.get("LOOKBACK_DAYS", "365"))
WINDOW_START = (datetime.now(timezone.utc) - timedelta(days=LOOKBACK_DAYS)).strftime("%Y-%m-%dT%H:%M:%SZ")

AUTHOR = "author { login __typename }"


def graphql(query: str, variables: dict) -> dict:
    response = requests.post(
        GRAPHQL_URL,
        json={"query": query, "variables": variables},
        headers={"Authorization": f"Bearer {os.environ['GITHUB_TOKEN']}"},
        timeout=60,
    )
    response.raise_for_status()
    body = response.json()
    if body.get("errors"):
        raise RuntimeError(body["errors"])
    return body["data"]


def paginate(query: str, owner: str, name: str, path: str, since: str, extra: dict | None = None):
    """Yield nodes newest-updated first, stopping once they are older than `since`."""
    cursor = None
    while True:
        data = graphql(query, {"owner": owner, "name": name, "after": cursor, "since": since, **(extra or {})})
        connection = data["repository"][path]
        for node in connection["nodes"]:
            stamp = node.get("updatedAt") or node.get("publishedAt") or node.get("createdAt")
            if stamp and stamp < since:
                return
            yield node
        if not connection["pageInfo"]["hasNextPage"]:
            return
        cursor = connection["pageInfo"]["endCursor"]


def since(full_name: str) -> str:
    """Per-repo cursor, so a repo added later still backfills the whole window."""
    return dlt.current.resource_state().get("cursors", {}).get(full_name, WINDOW_START)


def incremental(full_name: str, nodes):
    """Pass nodes through and move the repo's cursor to the newest updatedAt seen."""
    newest = since(full_name)
    for node in nodes:
        newest = max(newest, node["updatedAt"])
        yield node
    dlt.current.resource_state().setdefault("cursors", {})[full_name] = newest


def split(full_name: str) -> tuple[str, str]:
    owner, name = full_name.split("/")
    return owner, name


@dlt.resource(write_disposition="append", table_name="repos")
def repos():
    query = """
    query($owner: String!, $name: String!) {
      repository(owner: $owner, name: $name) {
        nameWithOwner url description createdAt
        stargazerCount forkCount
        issues(states: OPEN) { totalCount }
        pullRequests(states: OPEN) { totalCount }
        primaryLanguage { name }
        licenseInfo { spdxId }
      }
    }"""
    snapshot_at = datetime.now(timezone.utc).isoformat()
    for full_name in REPOS:
        owner, name = split(full_name)
        repo = graphql(query, {"owner": owner, "name": name})["repository"]
        yield {
            "repo": full_name,
            "snapshot_at": snapshot_at,
            "url": repo["url"],
            "description": repo["description"],
            "created_at": repo["createdAt"],
            "stars": repo["stargazerCount"],
            "forks": repo["forkCount"],
            "open_issues": repo["issues"]["totalCount"],
            "open_pull_requests": repo["pullRequests"]["totalCount"],
            "language": (repo["primaryLanguage"] or {}).get("name"),
            "license": (repo["licenseInfo"] or {}).get("spdxId"),
        }


@dlt.resource(write_disposition="merge", primary_key=("repo", "number"), table_name="issues")
def issues():
    query = f"""
    query($owner: String!, $name: String!, $after: String, $since: DateTime) {{
      repository(owner: $owner, name: $name) {{
        issues(first: 100, after: $after, orderBy: {{field: UPDATED_AT, direction: DESC}}, filterBy: {{since: $since}}) {{
          pageInfo {{ hasNextPage endCursor }}
          nodes {{
            number title state createdAt updatedAt closedAt authorAssociation {AUTHOR}
            labels(first: 10) {{ nodes {{ name }} }}
            comments(first: 10) {{ nodes {{ createdAt authorAssociation {AUTHOR} }} }}
          }}
        }}
      }}
    }}"""
    for full_name in REPOS:
        owner, name = split(full_name)
        for node in incremental(full_name, paginate(query, owner, name, "issues", since(full_name))):
            yield {
                "repo": full_name,
                "number": node["number"],
                "title": node["title"],
                "state": node["state"],
                "created_at": node["createdAt"],
                "updated_at": node["updatedAt"],
                "closed_at": node["closedAt"],
                "author_login": (node["author"] or {}).get("login"),
                "author_type": (node["author"] or {}).get("__typename"),
                "author_association": node["authorAssociation"],
                "labels": [label["name"] for label in node["labels"]["nodes"]],
                "comments": [
                    {
                        "created_at": c["createdAt"],
                        "author_login": (c["author"] or {}).get("login"),
                        "author_type": (c["author"] or {}).get("__typename"),
                        "author_association": c["authorAssociation"],
                    }
                    for c in node["comments"]["nodes"]
                ],
            }


@dlt.resource(write_disposition="merge", primary_key=("repo", "number"), table_name="pull_requests")
def pull_requests():
    query = f"""
    query($owner: String!, $name: String!, $after: String) {{
      repository(owner: $owner, name: $name) {{
        pullRequests(first: 100, after: $after, orderBy: {{field: UPDATED_AT, direction: DESC}}) {{
          pageInfo {{ hasNextPage endCursor }}
          nodes {{
            number title state createdAt updatedAt closedAt mergedAt
            authorAssociation {AUTHOR} mergedBy {{ login }}
          }}
        }}
      }}
    }}"""
    for full_name in REPOS:
        owner, name = split(full_name)
        for node in incremental(full_name, paginate(query, owner, name, "pullRequests", since(full_name))):
            yield {
                "repo": full_name,
                "number": node["number"],
                "title": node["title"],
                "state": node["state"],
                "created_at": node["createdAt"],
                "updated_at": node["updatedAt"],
                "closed_at": node["closedAt"],
                "merged_at": node["mergedAt"],
                "author_login": (node["author"] or {}).get("login"),
                "author_type": (node["author"] or {}).get("__typename"),
                "author_association": node["authorAssociation"],
                "merged_by_login": (node["mergedBy"] or {}).get("login"),
            }


@dlt.resource(write_disposition="merge", primary_key=("repo", "tag_name"), table_name="releases")
def releases():
    query = """
    query($owner: String!, $name: String!, $after: String) {
      repository(owner: $owner, name: $name) {
        releases(first: 100, after: $after, orderBy: {field: CREATED_AT, direction: DESC}) {
          pageInfo { hasNextPage endCursor }
          nodes { tagName name createdAt publishedAt isPrerelease isDraft }
        }
      }
    }"""
    for full_name in REPOS:
        owner, name = split(full_name)
        for node in paginate(query, owner, name, "releases", WINDOW_START):
            if node["isDraft"]:
                continue
            yield {
                "repo": full_name,
                "tag_name": node["tagName"],
                "name": node["name"],
                "created_at": node["createdAt"],
                "published_at": node["publishedAt"],
                "is_prerelease": node["isPrerelease"],
            }


@dlt.source(name="github")
def github_source():
    return repos, issues, pull_requests, releases


if __name__ == "__main__":
    destination = os.environ.get("DESTINATION", "duckdb")
    if destination == "duckdb":
        os.makedirs("data", exist_ok=True)
        destination = dlt.destinations.duckdb("data/github.duckdb")
    pipeline = dlt.pipeline(pipeline_name="github", destination=destination, dataset_name="raw_github")
    print(pipeline.run(github_source()))
