{{ config(materialized='table') }}

SELECT
    company_id
  , schema_name
  , company_name
  , industry
  , signup_date AS signup_date
  , employee_count::INTEGER AS employee_count
FROM {{ ref('stg_companies') }}
