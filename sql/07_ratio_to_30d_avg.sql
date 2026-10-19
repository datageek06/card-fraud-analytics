WITH bucketed AS (
    SELECT
        CASE
            WHEN v.ratio_to_30d_avg IS NULL THEN '0. No history'
            WHEN v.ratio_to_30d_avg <  1 THEN '1. < 1x (below own average)'
            WHEN v.ratio_to_30d_avg <  3 THEN '2. 1x - 3x'
            WHEN v.ratio_to_30d_avg <  5 THEN '3. 3x - 5x'
            WHEN v.ratio_to_30d_avg < 10 THEN '4. 5x - 10x'
            ELSE '5. >= 10x (extreme)'
        END AS ratio_bucket,
        t.is_fraud,
        t.amt
    FROM public_core.fact_transactions t
    JOIN public_marts.mart_card_velocity v
      ON t.trans_num = v.trans_num
)
SELECT
    ratio_bucket,
    COUNT(*) AS total_transactions,
    COUNT(*) FILTER (WHERE is_fraud) AS fraud_transactions,
    ROUND(COUNT(*) FILTER (WHERE is_fraud) * 100.0 / COUNT(*), 3) AS fraud_rate_pct,
    ROUND(
        (COUNT(*) FILTER (WHERE is_fraud)::numeric / COUNT(*))
        / (SUM(COUNT(*) FILTER (WHERE is_fraud)) OVER ()::numeric / SUM(COUNT(*)) OVER ())
    , 2) AS lift_vs_baseline,
    ROUND(SUM(amt) FILTER (WHERE is_fraud)::numeric, 2) AS fraud_amount
FROM bucketed
GROUP BY ratio_bucket
ORDER BY ratio_bucket;

-- INSIGHT:
-- A transaction's size compared to the cardholder's 30-day average is the strongest fraud signal. 
-- Large spikes (10x+ baseline) are 26.5x riskier, while new/inactive cards with no history carry an 11.4% fraud rate.