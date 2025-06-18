# dbt-takehome @ Finally

This repository implements the multi-tenant dbt + Snowflake project.

## Architecture Overview

The project transforms tenant-specific financial data into unified, analysis-ready fact and dimension tables. Raw input is seeded from CSV files, each containing a `schema_name` column to simulate a schema-per-tenant architecture. The data pipeline is organized into two layers:

- `stg/` for cleaning and standardizing raw inputs
- `marts/` for business-facing reporting tables

## Multi-Tenancy Approach

Rather than querying across multiple schemas, tenant data is pre-unified via seeds, with tenant identity preserved through the `schema_name` column. A custom macro (`union_tenant_tables`) reads from each seed file and returns the full unified dataset. No schema iteration or dynamic SQL is required, which simplifies the project and matches the structure of the take-home prompt.

### Real-world considerations
In a real multi-tenant environment, the macro could dynamically UNION across schemas using information_schema. Here, we simulate that by selecting from unified seed files with a schema_name tag.
Here's the Jinja macro you could use in a real multi-tenant environment where each tenant has its own schema and identical table structure (e.g., comp_001.sde_users, comp_002.sde_users, etc.):

jinja
```
{% macro union_tenant_tables(raw_table_name) %}
  {# Get all tenant schema names from a seed or dimension table #}
  {% set tenant_schemas = dbt_utils.get_column_values(ref('sde_companies'), 'schema_name') %}

  {% set union_queries = [] %}

  {% for schema in tenant_schemas %}
    {% set query %}
      SELECT
          '{{ schema }}' AS schema_name
        , *
      FROM {{ schema }}.{{ raw_table_name }}
    {% endset %}

    {% do union_queries.append(query) %}
  {% endfor %}

  {{ return(union_queries | join('\nUNION ALL\n')) }}
{% endmacro %}
```

## Modeling Decisions

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
      The date spine begins several months before transaction data appears. I chose this early anchor date to ensure full coverage for any historical joins, future-ingested data, or backfill scenarios. The data could be even earlier to provide a consistent foundation for time-based transformations.

## Testing Strategy

- `not_null` and `unique` tests on primary keys in all staging models
- `not_null` and optional `unique` tests on key columns in marts
- Manual SQL sanity checks to validate grain and joinability

## Performance Considerations
This project uses views for staging models to prioritize modularity and rapid iteration. However, for real-world datasets at scale (e.g., multi-tenant transaction tables exceeding 200GB), performance tuning would be essential. 
Key strategies include:
Clustering Keys: On large fact tables, raw, or stg tables like fct_monthly_company_spend raw corp_card_transactions, clustering by company_id, transaction_date, or both would improve query pruning and scan efficiency in Snowflake.
Transient Tables in Staging: If the data volume in staging models grows significantly, materializing them as transient tables instead of views or ephemeral models can drastically reduce recomputation costs and improve downstream query performance.
Incremental Models: For append-only transactional data, converting staging or fact models to incremental materializations would also reduce compute cost over time.
In this take-home, I avoided those techniques to limit complexity, but the codebase can readily accommodate such modifications as scale demands increase.

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
