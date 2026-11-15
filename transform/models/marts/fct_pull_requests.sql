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
    repo_id || '/' || coalesce(author_login, 'ghost') as author_id,
    date_diff('minute', opened_at, merged_at) / 60.0 as hours_to_merge
from {{ ref('stg_pull_requests') }}
where opened_at >= current_date - interval ({{ var('lookback_days') }}) day
