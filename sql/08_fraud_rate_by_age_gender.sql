SELECT
    age_bucket,
    gender,
    SUM(cnt_transactions)                                                 AS total_txns,
    SUM(cnt_fraud)                                                        AS total_fraud_txns,
    ROUND(SUM(fraud_amount)::numeric, 2)                                  AS total_fraud_amount,
    ROUND(SUM(cnt_fraud) * 100.0 / SUM(cnt_transactions), 3)              AS fraud_rate_pct,
    ROUND(
        (SUM(cnt_fraud)::numeric / SUM(cnt_transactions))
        / (SUM(SUM(cnt_fraud)) OVER ()::numeric / SUM(SUM(cnt_transactions)) OVER ())
    , 2)                                                                  AS lift_vs_baseline,
    ROUND(SUM(fraud_amount) * 100.0 / SUM(SUM(fraud_amount)) OVER (), 2)  AS pct_of_total_fraud_loss
FROM public_marts.mart_segment_kpi
GROUP BY age_bucket, gender
ORDER BY total_fraud_amount DESC;

-- INSIGHT:
-- Fraud *rate* peaks for 45-59 and 60+ (both genders, ~0.48%-0.58%, lift up
-- to 1.64x), while 18-44 sits below baseline (lift 0.70x-0.94x). But 18-29
-- is such a high-volume segment that it holds the largest share of total
-- fraud dollar loss (17.9% male + 12.8% female = ~30.7% combined) despite a
-- below-average rate -- the same rate-vs-volume tension seen in the category
-- breakdown above.
