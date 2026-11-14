-- One row per release published in the lookback window.
select release_id, repo_id, tag_name, name, published_at, is_prerelease
from {{ ref('stg_releases') }}
where published_at >= current_date - interval ({{ var('lookback_days') }}) day
