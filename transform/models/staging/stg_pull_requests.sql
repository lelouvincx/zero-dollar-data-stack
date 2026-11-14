select
    repo || '#' || number as pull_request_id,
    repo as repo_id,
    number,
    title,
    lower(state) as state,
    cast(created_at as timestamp) as opened_at,
    cast(merged_at as timestamp) as merged_at,
    cast(closed_at as timestamp) as closed_at,
    author_login,
    merged_by_login,
    {{ author_type('repo', 'author_login', 'author_type') }} as author_type
from {{ source('raw_github', 'pull_requests') }}
