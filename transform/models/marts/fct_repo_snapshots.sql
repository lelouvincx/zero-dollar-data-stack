-- Stars, forks and open work per repo per day: the last snapshot of each day.
select repo_id, snapshot_date, stars, forks, open_issues, open_pull_requests
from {{ ref('stg_repo_snapshots') }}
qualify row_number() over (partition by repo_id, snapshot_date order by snapshot_at desc) = 1
