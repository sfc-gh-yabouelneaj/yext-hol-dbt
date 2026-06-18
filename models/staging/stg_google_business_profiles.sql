with source as (

    select * from {{ source('raw_data', 'google_business_profiles') }}

),

cleaned as (

    select
        gbp_id,
        name as gbp_name,
        address,
        city,
        state,
        zip,
        latitude,
        longitude,
        phone,
        website,
        primary_category,
        additional_categories,
        average_rating,
        total_reviews,
        is_verified,
        last_updated,

        -- Derived
        datediff('day', last_updated, current_date()) as days_since_update

    from source

)

select * from cleaned
