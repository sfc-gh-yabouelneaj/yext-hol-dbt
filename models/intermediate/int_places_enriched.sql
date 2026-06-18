with places as (

    select * from {{ ref('stg_foursquare_places') }}

),

categories_flattened as (

    select
        fsq_place_id,
        listagg(value::string, ', ') within group (order by index) as category_labels_flat
    from places,
        lateral flatten(input => fsq_category_labels) f
    group by fsq_place_id

),

enriched as (

    select
        p.fsq_place_id,
        p.place_name,
        p.latitude,
        p.longitude,
        p.address,
        p.city,
        p.state,
        p.zip_code,
        p.country,
        p.created_at,
        p.refreshed_at,
        p.closed_at,
        p.place_status,
        p.phone_number,
        p.website,
        p.email,
        p.instagram_handle,
        p.twitter_handle,
        p.flag_count,
        p.unresolved_flags,
        p.geom,

        -- Flattened categories
        c.category_labels_flat as categories,

        -- Data freshness
        datediff('day', p.refreshed_at, current_date()) as days_since_refresh,

        -- Data age
        datediff('day', p.created_at, current_date()) as days_since_created,

        -- Contact completeness score (0-5)
        (iff(p.phone_number is not null, 1, 0)
         + iff(p.website is not null, 1, 0)
         + iff(p.email is not null, 1, 0)
         + iff(p.instagram_handle is not null, 1, 0)
         + iff(p.twitter_handle is not null, 1, 0)
        ) as contact_completeness_score,

        -- Has social presence
        iff(p.instagram_handle is not null or p.twitter_handle is not null, true, false) as has_social_presence

    from places p
    left join categories_flattened c
        on p.fsq_place_id = c.fsq_place_id

)

select * from enriched
