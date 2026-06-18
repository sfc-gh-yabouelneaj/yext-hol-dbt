-- Test: All ratings should be between 1 and 5

select
    review_id,
    rating
from {{ ref('stg_customer_reviews') }}
where rating < 1 or rating > 5
