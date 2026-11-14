{# Bots: GitHub Apps, and user accounts that are bots by name (*[bot], *-bot, *automation*). #}
{% macro is_bot(login, typename) -%}
  ({{ typename }} = 'Bot' or {{ login }} like '%[bot]' or {{ login }} like '%-bot' or {{ login }} ilike '%automation%')
{%- endmacro %}

{# core_team: listed in stg_maintainers for the repo. GitHub hides private org members as
   CONTRIBUTOR, so the association alone undercounts the core team. #}
{% macro author_type(repo, login, typename) -%}
  case
    when {{ is_bot(login, typename) }} then 'bot'
    when exists (
      select 1 from {{ ref('stg_maintainers') }} m
      where m.repo_id = {{ repo }} and m.login = {{ login }}
    ) then 'core_team'
    else 'community'
  end
{%- endmacro %}
