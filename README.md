# dbt-takehome @ Finally

This repository implements the multi-tenant dbt + Snowflake take-home project for Finally.

## Architecture Overview

The project transforms tenant-specific financial data into unified, analysis-ready fact and dimension tables. Raw input is seeded from CSV files, each containing a `schema_name` column to simulate a schema-per-tenant architecture. The data pipeline is organized into two layers:

- `stg/` for cleaning and standardizing raw inputs
- `marts/` for business-facing reporting tables

## Multi-Tenancy Strategy

Rather than querying across multiple schemas, tenant data is pre-unified via seeds, with tenant identity preserved through the `schema_name` column. A custom macro (`union_tenant_tables`) reads from each seed file and returns the full unified dataset. No schema iteration or dynamic SQL is required, which simplifies the project and matches the structure of the take-home prompt.

## Model Breakdown

### Staging Layer (`stg/`)

Each staging model:
- Renames columns to consistent `snake_case`
- Applies basic type casting (e.g., `amount_usd` to `DECIMAL`, dates to `DATE`)
- Deduplicates records where necessary (e.g., transactions using `ROW_NUMBER()`)
- Normalizes key fields (e.g., coalescing missing `merchant_category_description` to `'unknown'`)

### Marts Layer (`marts/`)

- `dim_companies`: One row per company, sourced from `stg_companies`
- `fct_monthly_company_spend`: Aggregates total `amount_usd` and transaction counts per `company_id` and month
- `fct_daily_outstanding_balances`: For each `company_id` and date, calculates:
    - Daily spend and repayment totals
    - Running cumulative totals
    - Outstanding balance using `cumulative_spend - cumulative_repayment`
    - A date spine ensures completeness even for dates with no transactions

## Testing Strategy

- `not_null` and `unique` tests on primary keys in all staging models
- `not_null` and optional `unique` tests on key columns in marts
- Manual SQL sanity checks to validate grain and joinability

## Configuration Details

- Staging models are materialized as `views`
- Mart models are materialized as `tables`
- Schemas are explicitly set via `+schema:` in `dbt_project.yml` to avoid default folder-based naming
- Seeds are directed to the `stg` schema
- A macro override (`generate_schema_name`) prevents automatic schema name concatenation

## Known Issue

A `not_null` test on `fct_monthly_company_spend.month` intermittently fails despite no null `transaction_date` values in the source. This may be caused by a stale cache or schema mismatch and will be resolved separately.

## Usage

```bash
dbt deps
dbt seed
dbt run
dbt test
