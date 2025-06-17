{{ config(materialized='view') }}

WITH unioned AS (
    {{ union_tenant_tables('sde_gl_postings') }}
)

SELECT
    POSTING_ID AS posting_id
  , COMPANY_ID AS company_id
  , TRANSACTION_ID AS transaction_id
  , REPORT_ID AS report_id
  , POSTING_DATE::DATE AS posted_at
  , POSTING_DATE as posting_date
  , ACCOUNT_NUMBER AS account_number
  , ACCOUNT_NAME AS account_name
  , ACCOUNT_TYPE AS account_type
  , DEBIT_USD::DECIMAL(20, 2) as debit_usd
  , CREDIT_USD::DECIMAL(20, 2) as credit_usd
  , "DESCRIPTION" as "description"
FROM unioned
