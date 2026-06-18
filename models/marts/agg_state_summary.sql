with locations as (

    select * from {{ ref('dim_locations') }}

)

select
    state,
    count(*) as total_locations,
    sum(case when place_status = 'active' then 1 else 0 end) as active_locations,
    sum(case when place_status = 'closed' then 1 else 0 end) as closed_locations,
    round(avg(overall_health_score), 1) as avg_health_score,
    round(avg(avg_rating), 2) as avg_rating,
    sum(total_reviews) as total_reviews,
    round(avg(response_rate_pct), 1) as avg_response_rate,
    round(avg(contact_completeness_score), 2) as avg_contact_score,
    sum(total_listings) as total_listings,
    sum(healthy_listings) as healthy_listings,
    sum(error_listings) as error_listings

from locations
group by state
order by total_locations desc
