with enriched as (

    select * from {{ ref('int_places_enriched') }}

)

select
    state,
    count(*) as total_places,
    sum(case when place_status = 'active' then 1 else 0 end) as active_places,
    sum(case when place_status = 'closed' then 1 else 0 end) as closed_places,
    round(avg(contact_completeness_score), 2) as avg_contact_score,
    sum(case when has_social_presence then 1 else 0 end) as places_with_social,
    round(avg(days_since_refresh), 1) as avg_days_since_refresh,
    sum(flag_count) as total_flags

from enriched
group by state
order by total_places desc
