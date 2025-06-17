{{ config(materialized='view') }}

WITH unioned AS (
    {{ union_tenant_tables('sde_companies') }}
)

SELECT
    COMPANY_ID AS company_id
  , SCHEMA_NAME AS schema_name
  , COMPANY_NAME AS company_name
  , INDUSTRY AS industry
  , SIGNUP_DATE as signup_date
  , EMPLOYEE_COUNT as employee_count
FROM unioned
