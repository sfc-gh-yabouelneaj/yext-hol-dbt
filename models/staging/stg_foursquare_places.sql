with source as (

    select * from {{ source('raw_data', 'foursquare_places') }}

),

cleaned as (

    select
        fsq_place_id,
        name as place_name,
        latitude,
        longitude,
        address,
        locality as city,
        region as state,
        postcode as zip_code,
        admin_region,
        country,

        -- Parse dates from text to proper date types
        try_to_date(date_created) as created_at,
        try_to_date(date_refreshed) as refreshed_at,
        try_to_date(date_closed) as closed_at,

        -- Contact info
        tel as phone_number,
        website,
        email,
        facebook_id,
        instagram as instagram_handle,
        twitter as twitter_handle,

        -- Category arrays (keep as-is for downstream flattening)
        fsq_category_ids,
        fsq_category_labels,

        -- Flags & metadata
        placemaker_url,
        unresolved_flags,
        array_size(unresolved_flags) as flag_count,

        -- Geospatial
        bbox,
        geom,

        -- Derived status
        case
            when date_closed is not null then 'closed'
            else 'active'
        end as place_status

    from source

)

select * from cleaned
