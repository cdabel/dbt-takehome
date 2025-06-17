{{ config(materialized='table') }}

WITH date_spine AS (
    -- Adjust the date range as needed
    SELECT
        DATEADD(DAY, SEQ4(), '2022-01-01') AS date_day
    FROM TABLE(GENERATOR(ROWCOUNT => 1000))
),

companies AS (
    SELECT DISTINCT company_id
    FROM {{ ref('dim_companies') }}
),

company_day AS (
    SELECT
        c.company_id
      , d.date_day
    FROM companies c
    CROSS JOIN date_spine d
),

daily_spend AS (
    SELECT
        company_id
      , transaction_date AS date_day
      , SUM(amount_usd) AS daily_spend_usd
    FROM {{ ref('stg_corp_card_transactions') }}
    GROUP BY company_id, date_day
),

daily_repayments AS (
    SELECT
        company_id
      , repayment_date AS date_day
      , SUM(repayment_amount_usd) AS daily_repayment_usd
    FROM {{ ref('stg_repayments') }}
    GROUP BY company_id, date_day
),

joined AS (
    SELECT
        cd.company_id
      , cd.date_day
      , COALESCE(ds.daily_spend_usd, 0) AS daily_spend_usd
      , COALESCE(dr.daily_repayment_usd, 0) AS daily_repayment_usd
    FROM company_day cd
    LEFT JOIN daily_spend ds
        ON cd.company_id = ds.company_id AND cd.date_day = ds.date_day
    LEFT JOIN daily_repayments dr
        ON cd.company_id = dr.company_id AND cd.date_day = dr.date_day
)

SELECT
    company_id
  , date_day
  , daily_spend_usd
  , daily_repayment_usd
  , SUM(daily_spend_usd) OVER (
        PARTITION BY company_id ORDER BY date_day
    ) AS cumulative_spend_usd
  , SUM(daily_repayment_usd) OVER (
        PARTITION BY company_id ORDER BY date_day
    ) AS cumulative_repayment_usd
  , SUM(daily_spend_usd) OVER (PARTITION BY company_id ORDER BY date_day)
    - SUM(daily_repayment_usd) OVER (PARTITION BY company_id ORDER BY date_day)
    AS outstanding_balance_usd
FROM joined
