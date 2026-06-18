-- Test: No reviews should reference a location that doesn't exist in our places table
-- This catches data integrity issues between review feeds and location data

select
    r.entity_id,
    count(*) as orphan_review_count
from {{ ref('stg_customer_reviews') }} r
left join {{ ref('stg_foursquare_places') }} p
    on r.entity_id = p.fsq_place_id
where p.fsq_place_id is null
group by r.entity_id
