-- Test: Health score should always be between 0 and 100

select
    location_id,
    overall_health_score
from {{ ref('dim_locations') }}
where overall_health_score < 0 or overall_health_score > 100
