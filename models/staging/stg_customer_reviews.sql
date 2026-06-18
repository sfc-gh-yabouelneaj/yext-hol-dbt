with source as (

    select * from {{ source('raw_data', 'customer_reviews') }}

),

cleaned as (

    select
        review_id,
        entity_id,
        platform,
        rating,
        review_text,
        author_name,
        review_date,
        response_text,
        response_date,
        sentiment,
        flagged,

        -- Derived fields
        case when response_text is not null then true else false end as has_response,
        case when response_date is not null
            then datediff('day', review_date, response_date)
            else null
        end as response_time_days,
        datediff('day', review_date, current_date()) as days_since_review

    from source
    where review_id is not null

)

select * from cleaned
