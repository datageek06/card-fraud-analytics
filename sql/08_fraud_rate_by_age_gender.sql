SELECT
    age_bucket,
    gender,
    SUM(cnt_transactions) AS total_txns,
    SUM(cnt_fraud) AS total_fraud_txns,
    ROUND(SUM(fraud_amount)::numeric, 2) AS total_fraud_amount,
    ROUND(SUM(cnt_fraud) * 100.0 / SUM(cnt_transactions), 3) AS fraud_rate_pct,
    ROUND(
        (SUM(cnt_fraud)::numeric / SUM(cnt_transactions))
        / (SUM(SUM(cnt_fraud)) OVER ()::numeric / SUM(SUM(cnt_transactions)) OVER ())
    , 2) AS lift_vs_baseline,
    ROUND(SUM(fraud_amount) * 100.0 / SUM(SUM(fraud_amount)) OVER (), 2)  AS pct_of_total_fraud_loss
FROM public_marts.mart_segment_kpi
GROUP BY age_bucket, gender
ORDER BY total_fraud_amount DESC;

-- INSIGHT:
-- Older cardholders (45+) have higher fraud rates, 
-- but younger users (18–29) generate ~30.7% of total dollar losses due to higher overall transaction volume.
