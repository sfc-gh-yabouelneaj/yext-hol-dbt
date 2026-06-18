with enriched as (

    select * from {{ ref('int_places_enriched') }}

)

select
    fsq_place_id,
    place_name,
    categories,
    address,
    city,
    state,
    zip_code,
    country,
    latitude,
    longitude,
    geom,
    place_status,
    phone_number,
    website,
    email,
    instagram_handle,
    twitter_handle,
    contact_completeness_score,
    has_social_presence,
    created_at,
    refreshed_at,
    closed_at,
    days_since_refresh,
    days_since_created

from enriched
