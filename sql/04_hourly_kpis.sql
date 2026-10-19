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
-- Fraud spikes late at night and early in the morning (10 PM to 3 AM), making these transactions 4–10x riskier than daytime ones.
