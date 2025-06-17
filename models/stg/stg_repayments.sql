{{ config(materialized='view') }}

WITH unioned AS (
    {{ union_tenant_tables('sde_repayments') }}
)

SELECT
    REPAYMENT_ID AS repayment_id
  , COMPANY_ID AS company_id
  , REPAYMENT_DATE::DATE AS repayment_date
  , REPAYMENT_AMOUNT_USD::DECIMAL(20, 2) AS repayment_amount_usd
  , METHOD as method
FROM unioned
