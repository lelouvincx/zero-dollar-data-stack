select
    repo || '@' || tag_name as release_id,
    repo as repo_id,
    tag_name,
    name,
    cast(coalesce(published_at, created_at) as timestamp) as published_at,
    is_prerelease
from {{ source('raw_github', 'releases') }}
