with enriched as (

    select * from {{ ref('int_places_enriched') }}
    where flag_count > 0

),

flags_flattened as (

    select
        e.fsq_place_id,
        e.place_name,
        e.city,
        e.state,
        e.place_status,
        e.categories,
        e.days_since_refresh,
        e.contact_completeness_score,
        f.value::string as issue_type
    from enriched e,
        lateral flatten(input => e.unresolved_flags) f

)

select
    fsq_place_id,
    place_name,
    city,
    state,
    place_status,
    categories,
    issue_type,
    days_since_refresh,
    contact_completeness_score,
    case
        when issue_type = 'permanently_closed_unverified' then 'critical'
        when issue_type = 'duplicate_suspected' then 'high'
        when issue_type in ('phone_disconnected', 'website_404') then 'medium'
        when issue_type in ('hours_missing', 'address_unverified') then 'low'
        else 'unknown'
    end as issue_severity

from flags_flattened
