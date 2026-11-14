-- Latest snapshot of each repo.
select
    repo as repo_id,
    split_part(repo, '/', 1) as owner,
    split_part(repo, '/', 2) as name,
    url,
    description,
    language,
    license,
    cast(created_at as timestamp) as created_at,
    stars,
    forks,
    open_issues,
    open_pull_requests,
    cast(snapshot_at as timestamp) as snapshot_at
from {{ source('raw_github', 'repos') }}
qualify row_number() over (partition by repo order by snapshot_at desc) = 1
