-- One row per pull request opened in the lookback window.
select
    pull_request_id,
    repo_id,
    number,
    title,
    state,
    opened_at,
    merged_at,
    closed_at,
    merged_at is not null as is_merged,
    author_login,
    author_type,
    date_diff('minute', opened_at, merged_at) / 60.0 as hours_to_merge
from {{ ref('stg_pull_requests') }}
where opened_at >= current_date - interval ({{ var('lookback_days') }}) day
