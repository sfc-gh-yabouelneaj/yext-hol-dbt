with locations as (

    select * from {{ ref('dim_locations') }}

),

brand_stats as (

    select
        place_name as brand,
        count(*) as location_count,
        sum(case when place_status = 'active' then 1 else 0 end) as active_locations,
        round(avg(overall_health_score), 1) as avg_health_score,
        round(avg(avg_rating), 2) as avg_rating,
        sum(total_reviews) as total_reviews,
        round(avg(response_rate_pct), 1) as avg_response_rate,
        round(avg(total_listings), 1) as avg_listings_per_location,
        round(avg(contact_completeness_score), 2) as avg_contact_completeness,
        count(distinct state) as states_present

    from locations
    group by place_name
    having count(*) >= 3

)

select *
from brand_stats
order by location_count desc, avg_health_score desc
