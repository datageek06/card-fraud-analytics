SELECT
    CASE
        WHEN distance_km IS NULL THEN '5. Unknown'
        WHEN distance_km <  10 THEN '1. < 10 km (home area)'
        WHEN distance_km >= 10  AND distance_km < 50 THEN '2. 10 - 50 km (nearby towns)'
        WHEN distance_km >= 50  AND distance_km < 100 THEN '3. 50 - 100 km'
        ELSE '4. >= 100 km (long distance / online)'
    END AS distance_bucket,
    COUNT(*) AS total_transactions,
    COUNT(*) FILTER (WHERE is_fraud) AS fraud_transactions,
    ROUND(COUNT(*) FILTER (WHERE is_fraud) * 100.0 / COUNT(*), 3) AS fraud_rate_pct,
    ROUND(AVG(amt) FILTER (WHERE is_fraud)::numeric, 2) AS avg_fraud_amount,
    ROUND(AVG(amt) FILTER (WHERE NOT is_fraud)::numeric, 2) AS avg_legit_amount
FROM public_core.fact_transactions
GROUP BY 1
ORDER BY 1;

-- INSIGHT:
-- Customer-to-merchant distance has no relationship with fraud. The fraud rate remains flat (around 0.33%) across all distances.