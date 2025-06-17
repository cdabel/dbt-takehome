{{ config(materialized='view') }}

WITH unioned AS (
    {{ union_tenant_tables('sde_corp_card_transactions') }}
),

sequence_transactions AS (
    SELECT *
    FROM (
        SELECT *
             , ROW_NUMBER() OVER (PARTITION BY TRANSACTION_ID ORDER BY LAST_UPDATED_TS DESC) AS row_num
        FROM unioned
    )
    WHERE row_num = 1
)

SELECT
    SCHEMA_NAME AS schema_name
  , TRANSACTION_ID AS transaction_id
  , USER_ID AS user_id
  , COMPANY_ID AS company_id
  , CARD_ID AS card_id
  , TRANSACTION_DATE::DATE AS transaction_date
  , MERCHANT_NAME AS merchant_name
  , MERCHANT_CATEGORY_CODE AS MERCHANT_CATEGORY_CODE
  , COALESCE(LOWER(TRIM(MERCHANT_CATEGORY_DESCRIPTION)), 'unknown') AS merchant_category_description
  , AMOUNT_USD::DECIMAL(20, 2) AS amount_usd
  , CURRENCY AS currency
  , "DESCRIPTION" as "description"
  , LAST_UPDATED_TS::TIMESTAMP AS last_updated_ts
FROM sequence_transactions
