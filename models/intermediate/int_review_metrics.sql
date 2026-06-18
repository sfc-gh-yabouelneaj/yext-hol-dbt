with reviews as (

    select * from {{ ref('stg_customer_reviews') }}

),

metrics as (

    select
        entity_id,
        count(*) as total_reviews,
        round(avg(rating), 2) as avg_rating,
        sum(case when rating >= 4 then 1 else 0 end) as positive_reviews,
        sum(case when rating <= 2 then 1 else 0 end) as negative_reviews,
        sum(case when has_response then 1 else 0 end) as responded_reviews,
        round(
            sum(case when has_response then 1 else 0 end)::float / nullif(count(*), 0) * 100,
            1
        ) as response_rate_pct,
        round(avg(response_time_days), 1) as avg_response_time_days,
        min(review_date) as first_review_date,
        max(review_date) as last_review_date,
        sum(case when flagged then 1 else 0 end) as flagged_reviews,

        -- Platform breakdown
        sum(case when platform = 'Google' then 1 else 0 end) as google_reviews,
        sum(case when platform = 'Yelp' then 1 else 0 end) as yelp_reviews,
        sum(case when platform = 'Facebook' then 1 else 0 end) as facebook_reviews,

        -- Sentiment breakdown
        sum(case when sentiment = 'POSITIVE' then 1 else 0 end) as positive_sentiment,
        sum(case when sentiment = 'NEGATIVE' then 1 else 0 end) as negative_sentiment

    from reviews
    group by entity_id

)

select * from metrics
