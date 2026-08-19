{{ config(
    materialized='table',
    indexes=[
      {'columns': ['day_of_week', 'hour']}
    ]
) }}

-- Fraud rate by hour of day and day of week, with a lift figure against the
-- overall baseline rate. Ported from sql/04_hourly_kpis.sql.
--
-- Finding this surfaces: fraud is heavily concentrated at 22:00-03:00, which averages
-- 3.7x the baseline rate and peaks at 6.7x (Tuesday 23:00, 2.3% fraud rate), while
-- 04:00-11:00 averages 0.26x. Hour of day is a cheap real-time signal because it is
-- available before a card has any history at all.
--
-- Grain: one row per day_of_week x hour (168 rows).

WITH baseline AS (
    SELECT COUNT(*) FILTER (WHERE is_fraud)::numeric / NULLIF(COUNT(*), 0) AS base_rate
    FROM {{ ref('fact_transactions') }}
),

cells AS (
    SELECT
        day_of_week,
        day_name,
        hour,
        COUNT(*)                         AS cnt_transactions,
        COUNT(*) FILTER (WHERE is_fraud) AS cnt_fraud,
        COALESCE(SUM(amt) FILTER (WHERE is_fraud), 0) AS fraud_amount
    FROM {{ ref('fact_transactions') }}
    GROUP BY day_of_week, day_name, hour
)

SELECT
    c.day_of_week,   -- Postgres DOW: 0=Sunday .. 6=Saturday, same as fact_transactions
    c.day_name,
    c.hour,
    c.cnt_transactions,
    c.cnt_fraud,
    ROUND(c.cnt_fraud * 100.0 / NULLIF(c.cnt_transactions, 0), 3) AS fraud_rate_pct,
    ROUND((c.cnt_fraud::numeric / NULLIF(c.cnt_transactions, 0)) / NULLIF(b.base_rate, 0), 2) AS lift_vs_baseline,
    ROUND(c.fraud_amount::numeric, 2) AS fraud_amount,

    -- the original ad-hoc query dropped cells under 100 transactions outright.
    -- Here they are kept and flagged instead, so the mart stays complete and the
    -- filtering decision belongs to whoever is reading it.
    (c.cnt_transactions >= 100) AS has_enough_volume

FROM cells c
CROSS JOIN baseline b
