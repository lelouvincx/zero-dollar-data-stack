-- One row per issue opened in the lookback window.
with issues as (
    select *
    from {{ ref('stg_issues') }}
    where opened_at >= current_date - interval ({{ var('lookback_days') }}) day
),

-- A maintainer's first reply: the first comment by the core team, not by the issue's author.
-- Only the first 10 comments are loaded, so a later first reply counts as no reply.
first_response as (
    select c.issue_id, min(c.commented_at) as first_response_at
    from {{ ref('stg_issue_comments') }} c
    join issues i using (issue_id)
    where c.author_type = 'core_team'
      and c.author_login is distinct from i.author_login
      and c.commented_at >= i.opened_at
    group by 1
)

select
    i.issue_id,
    i.repo_id,
    i.number,
    i.title,
    i.state,
    i.opened_at,
    i.closed_at,
    i.author_login,
    i.author_type,
    f.first_response_at,
    date_diff('minute', i.opened_at, f.first_response_at) / 60.0 as hours_to_first_response
from issues i
left join first_response f using (issue_id)
