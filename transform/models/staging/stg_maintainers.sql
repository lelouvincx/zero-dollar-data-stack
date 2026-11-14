-- People with write access to a repo: anyone who merged a pull request, plus anyone
-- GitHub shows as its owner, member or collaborator. Merging catches the engineers whose
-- org membership is private, whom GitHub labels CONTRIBUTOR.
with seen as (
    select repo, merged_by_login as login, 'Merged a PR' as evidence
    from {{ source('raw_github', 'pull_requests') }}
    where merged_by_login is not null

    union all
    select repo, author_login, 'Association ' || author_association
    from {{ source('raw_github', 'pull_requests') }}
    where author_association in ('OWNER', 'MEMBER', 'COLLABORATOR')

    union all
    select repo, author_login, 'Association ' || author_association
    from {{ source('raw_github', 'issues') }}
    where author_association in ('OWNER', 'MEMBER', 'COLLABORATOR')

    union all
    select i.repo, c.author_login, 'Association ' || c.author_association
    from {{ source('raw_github', 'issues__comments') }} c
    join {{ source('raw_github', 'issues') }} i on c._dlt_parent_id = i._dlt_id
    where c.author_association in ('OWNER', 'MEMBER', 'COLLABORATOR')
)

select repo as repo_id, login, list(distinct evidence order by evidence) as evidence
from seen
where login is not null and not {{ is_bot('login', "''") }}
group by 1, 2
