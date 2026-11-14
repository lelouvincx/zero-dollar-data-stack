select
    repo as repo_id,
    cast(snapshot_at as timestamp) as snapshot_at,
    cast(snapshot_at as date) as snapshot_date,
    stars,
    forks,
    open_issues,
    open_pull_requests
from {{ source('raw_github', 'repos') }}
