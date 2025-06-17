{{ config(materialized='view') }}

WITH unioned AS (
    {{ union_tenant_tables('sde_expense_reports') }}
)

SELECT
    REPORT_ID AS report_id
  , USER_ID AS user_id
  , COMPANY_ID AS company_id
  , SUBMITTED_AT::TIMESTAMP AS submitted_at
  , APPROVED_AT::TIMESTAMP AS approved_at
  , "STATUS" AS status
  , REPORT_TOTAL_AMOUNT_USD::DECIMAL(20, 2) AS report_total_amount_usd
  , PURPOSE AS purpose 
  , NOTES AS notes
FROM unioned
