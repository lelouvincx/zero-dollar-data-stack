-- One row per (repo, login) for every author of an issue or pull request in the marts.
-- The same login can be core team in one repo and community in another, so the grain is per repo.
with authors as (
    -- Deleted accounts have no login; GitHub shows them as @ghost.
    select repo_id, coalesce(author_login, 'ghost') as login, author_type
    from {{ ref('stg_issues') }}
    where opened_at >= current_date - interval ({{ var('lookback_days') }}) day

    union

    select repo_id, coalesce(author_login, 'ghost'), author_type
    from {{ ref('stg_pull_requests') }}
    where opened_at >= current_date - interval ({{ var('lookback_days') }}) day
)

select
    a.repo_id || '/' || a.login as author_id,
    a.repo_id,
    a.login,
    a.author_type,
    case when a.author_type = 'core_team' then m.evidence end as core_team_evidence
from authors a
left join {{ ref('stg_maintainers') }} m using (repo_id, login)
