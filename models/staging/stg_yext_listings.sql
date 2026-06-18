with source as (

    select * from {{ source('raw_data', 'yext_listings') }}

),

cleaned as (

    select
        listing_id,
        entity_id,
        name as listing_name,
        address,
        city,
        state,
        zip,
        country,
        phone,
        website,
        hours as hours_json,
        photos,
        array_size(photos) as photo_count,
        publisher,
        publisher_url,
        listing_status,
        sync_status,
        last_synced_at,
        created_at,
        updated_at,

        -- Derived fields
        datediff('hour', last_synced_at, current_timestamp()) as hours_since_sync,
        case
            when listing_status = 'LIVE' and sync_status = 'SYNCED' then 'healthy'
            when listing_status = 'LIVE' and sync_status = 'OUT_OF_SYNC' then 'stale'
            when listing_status = 'LIVE' and sync_status = 'ERROR' then 'error'
            when listing_status = 'SUPPRESSED' then 'suppressed'
            when listing_status = 'OPTED_OUT' then 'opted_out'
            else 'pending'
        end as listing_health

    from source

)

select * from cleaned
