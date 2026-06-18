with reviews as (

    select * from {{ ref('stg_customer_reviews') }}

),

locations as (

    select location_id, place_name, city, state, categories
    from {{ ref('dim_locations') }}

)

select
    r.review_id,
    r.entity_id as location_id,
    l.place_name,
    l.city,
    l.state,
    l.categories,
    r.platform,
    r.rating,
    r.review_text,
    r.author_name,
    r.review_date,
    r.has_response,
    r.response_text,
    r.response_time_days,
    r.sentiment,
    r.flagged,
    r.days_since_review

from reviews r
left join locations l on r.entity_id = l.location_id
