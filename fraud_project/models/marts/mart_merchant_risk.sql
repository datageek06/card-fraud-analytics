select
    m.merchant,
    m.category,
    m.cnt_transactions,
    m.fraud_cnt,
    m.fraud_amount,

    -- fraud rate as a 0-1 ratio; 0 when the merchant has no transactions at all
    ROUND(CASE
        WHEN m.cnt_transactions > 0 THEN m.fraud_cnt::numeric / m.cnt_transactions
        ELSE 0
    END, 4) AS fraud_rate,

    -- expected loss per 1000 transactions
    CASE
        WHEN m.cnt_transactions > 0 THEN ROUND((m.fraud_cnt::numeric / m.cnt_transactions) * COALESCE(m.avg_fraud_amount, 0) * 1000, 2)
        ELSE 0
    END AS expected_loss_per_1000,

    CASE
        WHEN m.cnt_transactions >= 200 THEN TRUE
        ELSE FALSE
    END AS has_enough_volume

from {{ ref("dim_merchants") }} m
