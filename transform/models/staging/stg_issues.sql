select
    _dlt_id as issue_key,
    repo || '#' || number as issue_id,
    repo as repo_id,
    number,
    title,
    lower(state) as state,
    cast(created_at as timestamp) as opened_at,
    cast(closed_at as timestamp) as closed_at,
    author_login,
    {{ author_type('repo', 'author_login', 'author_type') }} as author_type
from {{ source('raw_github', 'issues') }}
