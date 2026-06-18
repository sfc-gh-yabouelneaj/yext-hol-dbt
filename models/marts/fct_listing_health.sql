with listings as (

    select * from {{ ref('stg_yext_listings') }}

),

locations as (

    select location_id, place_name, city, state
    from {{ ref('dim_locations') }}

)

select
    lst.listing_id,
    lst.entity_id as location_id,
    loc.place_name,
    loc.city,
    loc.state,
    lst.publisher,
    lst.listing_status,
    lst.sync_status,
    lst.listing_health,
    lst.hours_since_sync,
    lst.photo_count,
    lst.publisher_url,
    lst.created_at,
    lst.updated_at,

    -- Health flags
    case when lst.hours_since_sync > 168 then true else false end as is_stale,
    case when lst.sync_status = 'ERROR' then true else false end as has_sync_error,
    case when lst.photo_count = 0 then true else false end as missing_photos

from listings lst
left join locations loc on lst.entity_id = loc.location_id
