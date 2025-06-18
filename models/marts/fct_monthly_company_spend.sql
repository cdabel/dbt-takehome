{{ config(materialized='table') }}

WITH transactions AS (
    SELECT
        company_id 
      , DATE_TRUNC('month', transaction_date) AS "month"
      , amount_usd
    FROM {{ ref('stg_corp_card_transactions') }}
)

SELECT
    company_id AS company_id
  , "month"
  , SUM(amount_usd)::DECIMAL(20, 2) AS total_spend_usd
  , COUNT(*) AS transaction_count
FROM transactions
GROUP BY
    company_id
  , "month"
