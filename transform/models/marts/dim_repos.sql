-- One row per tracked repo. Stars, forks and open work live in fct_repo_snapshots.
select
    r.repo_id,
    coalesce(t.tool, r.name) as tool,
    coalesce(t.layer, 'Other') as layer,
    r.owner,
    r.url,
    r.description,
    r.language,
    r.license,
    r.created_at
from {{ ref('stg_repos') }} r
left join {{ ref('tool_layers') }} t using (repo_id)
