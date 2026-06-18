# Yext HOL - dbt Project on Snowflake

A hands-on lab demonstrating how to build and deploy dbt transformation pipelines directly in Snowflake using Cortex Code Desktop.

## Architecture

```
YEXT_HOL.RAW_DATA.FOURSQUARE_PLACES (2,000 rows)
  └─→ stg_foursquare_places (view)
        └─→ int_places_enriched (view)
              ├─→ dim_places (table)
              ├─→ fct_data_quality_issues (table)
              └─→ agg_state_summary (table)
```

## Quick Start

```bash
# Deploy to Snowflake
snow dbt deploy YEXT_HOL_TRANSFORMS --source . --database YEXT_HOL --schema ANALYTICS

# Execute models
snow dbt execute -c DEMO --database YEXT_HOL --schema ANALYTICS YEXT_HOL_TRANSFORMS run
```

## CI/CD

- **CI** (`.github/workflows/incoming_pr.yml`): On PR → deploys tester project → runs `build` (models + tests)
- **CD** (`.github/workflows/pr_merged.yml`): On merge to main → deploys production project object
