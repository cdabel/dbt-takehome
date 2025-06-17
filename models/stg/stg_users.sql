{{ config(materialized='view') }}

WITH unioned AS (
    {{ union_tenant_tables('sde_users') }}
)

SELECT
    SCHEMA_NAME AS schema_name
  , USER_ID AS user_id
  , COMPANY_ID AS company_id
  , USER_NAME AS user_name
  , DEPARTMENT AS department
  , JOIN_DATE::DATE AS join_date
FROM unioned
