WITH bucketed AS (
    SELECT
        CASE
            WHEN v.ratio_to_30d_avg IS NULL        THEN '0. No history'
            WHEN v.ratio_to_30d_avg <  1           THEN '1. < 1x (below own average)'
            WHEN v.ratio_to_30d_avg <  3           THEN '2. 1x - 3x'
            WHEN v.ratio_to_30d_avg <  5           THEN '3. 3x - 5x'
            WHEN v.ratio_to_30d_avg < 10           THEN '4. 5x - 10x'
            ELSE                                        '5. >= 10x (extreme)'
        END AS ratio_bucket,
        t.is_fraud,
        t.amt
    FROM public_core.fact_transactions t
    JOIN public_marts.mart_card_velocity v
      ON t.trans_num = v.trans_num
)
SELECT
    ratio_bucket,
    COUNT(*)                                                         AS total_transactions,
    COUNT(*) FILTER (WHERE is_fraud)                                 AS fraud_transactions,
    ROUND(COUNT(*) FILTER (WHERE is_fraud) * 100.0 / COUNT(*), 3)    AS fraud_rate_pct,
    ROUND(
        (COUNT(*) FILTER (WHERE is_fraud)::numeric / COUNT(*))
        / (SUM(COUNT(*) FILTER (WHERE is_fraud)) OVER ()::numeric / SUM(COUNT(*)) OVER ())
    , 2)                                                             AS lift_vs_baseline,
    ROUND(SUM(amt) FILTER (WHERE is_fraud)::numeric, 2)              AS fraud_amount
FROM bucketed
GROUP BY ratio_bucket
ORDER BY ratio_bucket;

-- INSIGHT:
-- The strongest single signal in this project. Fraud rate climbs from 0.13%
-- when a transaction is below the card's own 30-day average, to 7.2% at
-- 5x-10x that average, and 9.2% (26.5x lift) at >=10x. Cards with NO 30-day
-- history at all have an 11.4% fraud rate (32.9x lift) -- brand-new or
-- rarely-used cards are disproportionately risky. A transaction's size
-- relative to the cardholder's own recent baseline is far more predictive
-- than its raw dollar amount.