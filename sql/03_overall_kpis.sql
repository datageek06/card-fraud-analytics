select
    sum(cnt_transactions) as total_transactions,
    sum(cnt_fraud) as total_fraud,
    round(sum(total_amount), 2) as total_amount,
    round(sum(fraud_amount), 2) as total_fraud_amount,

    round(sum(cnt_fraud) * 100.0 / sum(cnt_transactions), 2) as fraud_rate_by_count_pct,
    round(sum(fraud_amount) * 100.0 / sum(total_amount), 2) as financial_loss_rate_pct,

    round(
        (sum(total_amount) - sum(fraud_amount))*1.0 /
        (sum(cnt_transactions) - sum(cnt_fraud)), 2
    ) as avg_not_fraud_amount,

    round(
        sum(fraud_amount)::numeric / sum(cnt_fraud), 2
    ) as avg_fraud_amount,


    round(
        (sum(fraud_amount)::numeric / sum(cnt_fraud))
            /
        ((sum(total_amount) - sum(fraud_amount))*1.0 /
        (sum(cnt_transactions) - sum(cnt_fraud)))
        , 2
    ) as fraud_to_legit_avg_ration

from public_marts.mart_daily_kpi;

-- INSIGHT:
-- Fraud accounts for only 0.35% of transactions but 2.60% of total dollar volume, 
-- with the average fraud transaction being 7.65x higher ($529 vs. $69).