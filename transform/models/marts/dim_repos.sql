select
    r.repo_id,
    coalesce(t.tool, r.name) as tool,
    coalesce(t.layer, 'Other') as layer,
    r.owner,
    r.url,
    r.description,
    r.language,
    r.license,
    r.created_at,
    r.stars,
    r.forks,
    r.open_issues,
    r.open_pull_requests,
    r.snapshot_at
from {{ ref('stg_repos') }} r
left join {{ ref('tool_layers') }} t using (repo_id)
