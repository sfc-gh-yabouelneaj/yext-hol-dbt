# Yext Hands-On Lab: dbt + DCM + Cortex Code Desktop

> **Duration:** 60 minutes
> **Audience:** Data engineers, analytics engineers, platform engineers
> **Tools:** Snowflake, Cortex Code Desktop (CoCo), Snow CLI, dbt Core

---

## Workshop Overview

In this hands-on lab you will:

1. **Explore** multi-source raw data (Foursquare Places, Yext Listings, Customer Reviews, Google Business Profiles)
2. **Build** a dbt transformation pipeline using Cortex Code Desktop's AI assistance
3. **Deploy** the dbt project as a native Snowflake object
4. **Test** data quality with dbt tests
5. **Understand** how CI/CD integrates with GitHub Actions

### Architecture

```
RAW_DATA (Sources)                    ANALYTICS (dbt-managed)
┌─────────────────────┐              ┌──────────────────────────────┐
│ FOURSQUARE_PLACES   │──┐           │ Staging (views)              │
│ (2,000 rows)        │  │           │ ├── stg_foursquare_places    │
├─────────────────────┤  │           │ ├── stg_yext_listings        │
│ YEXT_LISTINGS       │──┼──────────▶│ ├── stg_customer_reviews     │
│ (2,000 rows)        │  │           │ └── stg_google_business_prof │
├─────────────────────┤  │           ├──────────────────────────────┤
│ CUSTOMER_REVIEWS    │──┤           │ Intermediate (views)         │
│ (6,000 rows)        │  │           │ ├── int_review_metrics       │
├─────────────────────┤  │           │ └── int_listing_health       │
│ GOOGLE_BUSINESS_    │──┘           ├──────────────────────────────┤
│ PROFILES (1,233)    │              │ Marts (tables)               │
└─────────────────────┘              │ ├── dim_locations            │
                                     │ ├── fct_reviews              │
                                     │ ├── fct_listing_health       │
                                     │ ├── agg_brand_performance    │
                                     │ └── agg_state_summary        │
                                     └──────────────────────────────┘
```

### Model DAG

```
sources
├── foursquare_places ─→ stg_foursquare_places ─┐
├── yext_listings ─→ stg_yext_listings ──────────┼─→ int_listing_health ─┐
├── customer_reviews ─→ stg_customer_reviews ────┼─→ int_review_metrics ─┤
└── google_business_profiles ─→ stg_google_bp ───┘                       │
                                                                         ▼
                                                              dim_locations
                                                              ├── fct_reviews
                                                              ├── fct_listing_health
                                                              ├── agg_brand_performance
                                                              └── agg_state_summary
```

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| Snowflake Account | With ACCOUNTADMIN (or role with CREATE DBT PROJECT privilege) |
| Cortex Code Desktop | Installed and connected to your Snowflake account |
| Snow CLI | v3.20+ installed (`snow --version` to verify) |
| Database | `YEXT_HOL` with `RAW_DATA` and `ANALYTICS` schemas (pre-provisioned) |

---

## Exercise 1: Explore the Raw Data (10 min)

Open CoCo and connect to your Snowflake account. Run these queries to understand the source data:

```sql
-- Overview of available tables
SELECT TABLE_NAME, ROW_COUNT
FROM YEXT_HOL.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'RAW_DATA';

-- Sample Foursquare Places
SELECT * FROM YEXT_HOL.RAW_DATA.FOURSQUARE_PLACES LIMIT 10;

-- Sample Yext Listings
SELECT * FROM YEXT_HOL.RAW_DATA.YEXT_LISTINGS LIMIT 10;

-- Review distribution by platform
SELECT PLATFORM, COUNT(*), ROUND(AVG(RATING), 2) AS avg_rating
FROM YEXT_HOL.RAW_DATA.CUSTOMER_REVIEWS
GROUP BY PLATFORM;

-- Listing health overview
SELECT LISTING_STATUS, SYNC_STATUS, COUNT(*)
FROM YEXT_HOL.RAW_DATA.YEXT_LISTINGS
GROUP BY 1, 2
ORDER BY 3 DESC;
```

**Key observations to discuss:**
- Multiple data sources with overlapping entities
- Semi-structured data (JSON hours, ARRAY categories)
- Data quality issues (varying formats, nullable fields)

---

## Exercise 2: Generate a Staging Model with CoCo (10 min)

Use Cortex Code Desktop to generate a staging model from a natural language prompt.

### Try this CoCo prompt:

> "Create a dbt staging model called stg_yext_listings that reads from the source table
> YEXT_HOL.RAW_DATA.YEXT_LISTINGS. Clean the data by: parsing the hours JSON, counting photos,
> calculating hours since last sync, and creating a listing_health status field based on
> listing_status and sync_status combinations."

**Discussion points:**
- CoCo understands dbt conventions (sources, refs, naming)
- It generates idiomatic SQL with proper Snowflake functions
- You can iterate: "add a field for days since creation"

---

## Exercise 3: Build an Intermediate Model (10 min)

### CoCo prompt:

> "Create a dbt intermediate model called int_review_metrics that aggregates customer reviews
> by entity_id. Include: total reviews, average rating, response rate percentage, average
> response time in days, and breakdowns by platform (Google, Yelp, Facebook)."

### Follow-up prompt:

> "Now create int_listing_health that summarizes the listing status per entity. Count total
> listings, healthy vs stale vs error listings, and break down by publisher."

---

## Exercise 4: Create a Mart and Run Tests (15 min)

### CoCo prompt:

> "Create a dbt mart model called dim_locations that joins stg_foursquare_places with
> int_review_metrics and int_listing_health. Include a composite health score (0-100) based
> on: listing sync health (40%), average rating (30%), response rate (15%), and contact
> completeness (15%)."

### Deploy and run:

```bash
# Deploy the project to Snowflake
snow dbt deploy YEXT_HOL_TRANSFORMS \
  --source ./yext_hol_transforms \
  --database YEXT_HOL --schema ANALYTICS --force

# Execute all models
snow dbt execute -c DEMO \
  --database YEXT_HOL --schema ANALYTICS \
  YEXT_HOL_TRANSFORMS run

# Run tests
snow dbt execute -c DEMO \
  --database YEXT_HOL --schema ANALYTICS \
  YEXT_HOL_TRANSFORMS test
```

### Verify results:

```sql
-- Check materialized tables
SELECT TABLE_NAME, ROW_COUNT
FROM YEXT_HOL.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'ANALYTICS' AND TABLE_TYPE = 'BASE TABLE';

-- Top 10 healthiest brands
SELECT brand, location_count, avg_health_score, avg_rating
FROM YEXT_HOL.ANALYTICS.AGG_BRAND_PERFORMANCE
ORDER BY avg_health_score DESC
LIMIT 10;

-- Locations with sync errors
SELECT place_name, city, state, listing_health, hours_since_sync
FROM YEXT_HOL.ANALYTICS.FCT_LISTING_HEALTH
WHERE has_sync_error = TRUE
LIMIT 20;
```

---

## Exercise 5: CI/CD with GitHub (10 min)

The project is connected to GitHub at:
`https://github.com/sfc-gh-yabouelneaj/yext-hol-dbt`

### CI/CD workflow explained:

| Trigger | Workflow | What Happens |
|---------|----------|--------------|
| PR opened | `incoming_pr.yml` | Deploys tester project → runs `build` (models + tests) → fails PR on error |
| Merge to main | `pr_merged.yml` | Deploys production project object (new version) |

### Key Snow CLI commands for CI/CD:

```bash
# Deploy with force (create or update)
snow dbt deploy YEXT_HOL_TRANSFORMS --source . --force -x

# Build = run + test in DAG order (fails fast)
snow dbt execute -x YEXT_HOL_TRANSFORMS build --target default

# List deployed projects
snow dbt list -x
```

### The `-x` flag

In CI/CD runners, there's no `config.toml`. The `-x` (or `--temporary-connection`) flag tells Snow CLI to build the connection from environment variables (`SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_DATABASE`, `SNOWFLAKE_SCHEMA`).

---

## Exercise 6 (Bonus): Add a New Model with CoCo (5 min)

### Challenge prompt:

> "Add a new mart model called agg_review_trends that shows weekly review volume and
> average rating trends per brand over the last 12 months. Include week_start_date, brand,
> review_count, avg_rating, and a week-over-week change in rating."

After CoCo generates it:
1. Save the file to `models/marts/`
2. Re-deploy: `snow dbt deploy ... --force`
3. Execute: `snow dbt execute ... run --select agg_review_trends`

---

## Key Takeaways

| What You Did | CoCo Acceleration |
|---|---|
| Explored 4 raw data sources | CoCo explains schemas and suggests exploration queries |
| Built 9 dbt models across 3 layers | CoCo generates models from natural language in seconds |
| Added data quality tests | CoCo knows dbt test patterns (generic + singular) |
| Deployed as a Snowflake-native object | Single CLI command, version-controlled |
| Set up CI/CD pipelines | CoCo generates workflow YAML and explains the flow |

### Commands Cheat Sheet

```bash
# Deploy
snow dbt deploy <name> --source <path> --database <db> --schema <schema> [--force]

# Execute
snow dbt execute -c <connection> --database <db> --schema <schema> <name> <command>
# Commands: run, test, build, seed, show --select <model>

# List projects
snow dbt list [--in schema <schema>] [--database <db>]

# Show versions
SHOW VERSIONS IN DBT PROJECT <db>.<schema>.<name>;
```

---

## Resources

- [dbt Projects on Snowflake Docs](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake)
- [Snow CLI dbt Commands](https://docs.snowflake.com/en/developer-guide/snowflake-cli/dbt-commands)
- [CI/CD Tutorial](https://docs.snowflake.com/en/user-guide/tutorials/dbt-projects-on-snowflake-ci-cd-tutorial)
- [Cortex Code Desktop](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code)
