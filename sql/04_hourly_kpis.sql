WITH baseline AS (
    SELECT COUNT(*) FILTER (WHERE is_fraud)::numeric / COUNT(*) AS base_rate
    FROM public_core.fact_transactions
),
cells AS (
    SELECT
        day_of_week,
        hour,
        COUNT(*)                              AS cnt_transactions,
        COUNT(*) FILTER (WHERE is_fraud)      AS cnt_fraud,
        SUM(amt) FILTER (WHERE is_fraud)      AS fraud_amount
    FROM public_core.fact_transactions
    GROUP BY day_of_week, hour
)
SELECT
    c.day_of_week,
    c.hour,
    c.cnt_transactions,
    c.cnt_fraud,
    ROUND(c.cnt_fraud * 100.0 / c.cnt_transactions, 3)                 AS fraud_rate_pct,
    ROUND((c.cnt_fraud::numeric / c.cnt_transactions) / b.base_rate, 2) AS lift_vs_baseline,
    ROUND(COALESCE(c.fraud_amount, 0)::numeric, 2)                     AS fraud_amount
FROM cells c
CROSS JOIN baseline b
WHERE c.cnt_transactions >= 100
ORDER BY day_of_week, hour;

-- INSIGHT:
-- Fraud has a strong time-of-day pattern. Hours 22-23 and 0-3 show fraud
-- rates of ~0.7%-1.6% (lift 2x-4.7x vs the overall baseline), while hours
-- 4-11 are consistently near-zero (lift 0.1x-0.4x). Late night / early
-- morning transactions are 4-10x riskier than the daytime baseline -- a
-- strong, cheap real-time signal (hour-of-day alone) that's available even
-- before any per-card history exists.
