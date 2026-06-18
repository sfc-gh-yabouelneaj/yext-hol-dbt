with listings as (

    select * from {{ ref('stg_yext_listings') }}

),

listing_summary as (

    select
        entity_id,
        count(*) as total_listings,
        sum(case when listing_health = 'healthy' then 1 else 0 end) as healthy_listings,
        sum(case when listing_health = 'stale' then 1 else 0 end) as stale_listings,
        sum(case when listing_health = 'error' then 1 else 0 end) as error_listings,
        sum(case when listing_health = 'suppressed' then 1 else 0 end) as suppressed_listings,
        sum(case when publisher = 'Google' then 1 else 0 end) as google_listings,
        sum(case when publisher = 'Yelp' then 1 else 0 end) as yelp_listings,
        sum(case when publisher = 'Facebook' then 1 else 0 end) as facebook_listings,
        sum(case when publisher = 'Apple Maps' then 1 else 0 end) as apple_listings,
        round(avg(photo_count), 1) as avg_photos,
        min(hours_since_sync) as min_hours_since_sync,
        max(hours_since_sync) as max_hours_since_sync

    from listings
    group by entity_id

)

select * from listing_summary
