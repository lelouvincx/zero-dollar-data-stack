select
    i.repo || '#' || i.number as issue_id,
    c._dlt_list_idx as comment_index,
    cast(c.created_at as timestamp) as commented_at,
    c.author_login,
    {{ author_type('i.repo', 'c.author_login', 'c.author_type') }} as author_type
from {{ source('raw_github', 'issues__comments') }} c
join {{ source('raw_github', 'issues') }} i on c._dlt_parent_id = i._dlt_id
