{{ config(
    materialized='table',
    indexes=[
      {'columns': ['day_of_week', 'hour']}
    ]
) }}

WITH baseline AS (
    SELECT COUNT(*) FILTER (WHERE is_fraud)::numeric / NULLIF(COUNT(*), 0) AS base_rate
    FROM {{ ref('fact_transactions') }}
),

cells AS (
    SELECT
        day_of_week,
        day_name,
        hour,
        COUNT(*) AS cnt_transactions,
        COUNT(*) FILTER (WHERE is_fraud) AS cnt_fraud,
        COALESCE(SUM(amt) FILTER (WHERE is_fraud), 0) AS fraud_amount
    FROM {{ ref('fact_transactions') }}
    GROUP BY day_of_week, day_name, hour
)

SELECT
    c.day_of_week,
    c.day_name,
    c.hour,
    c.cnt_transactions,
    c.cnt_fraud,
    ROUND(c.cnt_fraud * 100.0 / NULLIF(c.cnt_transactions, 0), 3) AS fraud_rate_pct,
    ROUND((c.cnt_fraud::numeric / NULLIF(c.cnt_transactions, 0)) / NULLIF(b.base_rate, 0), 2) AS lift_vs_baseline,
    ROUND(c.fraud_amount::numeric, 2) AS fraud_amount,

    (c.cnt_transactions >= 100) AS has_enough_volume

FROM cells c
CROSS JOIN baseline b
