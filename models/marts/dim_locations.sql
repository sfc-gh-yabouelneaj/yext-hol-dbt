with places as (

    select * from {{ ref('stg_foursquare_places') }}

),

review_metrics as (

    select * from {{ ref('int_review_metrics') }}

),

listing_health as (

    select * from {{ ref('int_listing_health') }}

),

categories_flattened as (

    select
        fsq_place_id,
        listagg(value::string, ', ') within group (order by index) as category_labels_flat
    from places,
        lateral flatten(input => fsq_category_labels) f
    group by fsq_place_id

)

select
    p.fsq_place_id as location_id,
    p.place_name,
    c.category_labels_flat as categories,
    p.address,
    p.city,
    p.state,
    p.zip_code,
    p.country,
    p.latitude,
    p.longitude,
    p.geom,
    p.place_status,
    p.phone_number,
    p.website,
    p.email,
    p.instagram_handle,
    p.twitter_handle,
    p.created_at,
    p.refreshed_at,
    p.closed_at,

    -- Contact completeness (0-5)
    (iff(p.phone_number is not null, 1, 0)
     + iff(p.website is not null, 1, 0)
     + iff(p.email is not null, 1, 0)
     + iff(p.instagram_handle is not null, 1, 0)
     + iff(p.twitter_handle is not null, 1, 0)
    ) as contact_completeness_score,

    -- Review metrics
    coalesce(r.total_reviews, 0) as total_reviews,
    r.avg_rating,
    r.response_rate_pct,
    r.avg_response_time_days,

    -- Listing health
    coalesce(l.total_listings, 0) as total_listings,
    coalesce(l.healthy_listings, 0) as healthy_listings,
    coalesce(l.error_listings, 0) as error_listings,

    -- Overall health score (0-100)
    round(
        (coalesce(l.healthy_listings, 0)::float / nullif(coalesce(l.total_listings, 1), 0) * 40)
        + (least(coalesce(r.avg_rating, 0) / 5.0 * 30, 30))
        + (least(coalesce(r.response_rate_pct, 0) / 100.0 * 15, 15))
        + (least((iff(p.phone_number is not null, 1, 0)
                  + iff(p.website is not null, 1, 0)
                  + iff(p.email is not null, 1, 0)
                  + iff(p.instagram_handle is not null, 1, 0)
                  + iff(p.twitter_handle is not null, 1, 0))::float / 5.0 * 15, 15))
    , 1) as overall_health_score

from places p
left join categories_flattened c on p.fsq_place_id = c.fsq_place_id
left join review_metrics r on p.fsq_place_id = r.entity_id
left join listing_health l on p.fsq_place_id = l.entity_id
