WITH general_metrics AS (
    SELECT
        cc_num,
        COUNT(DISTINCT ts::date) AS active_days,
        -- average transactions per month = total transactions / distinct months seen
        COUNT(1)::numeric / NULLIF(COUNT(DISTINCT DATE_TRUNC('month', ts)), 0) AS avg_txn_per_month
    FROM {{ ref('stg_transactions') }}
    GROUP BY cc_num
),

first_fraud AS (
    SELECT
        cc_num,
        MIN(ts) AS first_fraud_date
    FROM {{ ref('stg_transactions') }}
    WHERE is_fraud IS TRUE
    GROUP BY cc_num
),

after_first_fraud AS (
    SELECT
        f.cc_num,
        SUM(CASE WHEN s.is_fraud IS TRUE THEN s.amt ELSE 0 END) AS fraud_amount_after_first,
        SUM(CASE WHEN s.is_fraud IS FALSE THEN s.amt ELSE 0 END) AS valid_amount_after_first
    FROM first_fraud f
    JOIN {{ ref('stg_transactions') }} s
        ON f.cc_num = s.cc_num
        AND s.ts > f.first_fraud_date
    GROUP BY f.cc_num
)

SELECT
    c.*,
    g.active_days,
    round(g.avg_txn_per_month, 2) as avg_txn_per_month,
    f.first_fraud_date,
    a.fraud_amount_after_first,
    a.valid_amount_after_first
FROM {{ ref('dim_customers') }} c
LEFT JOIN general_metrics g ON c.cc_num = g.cc_num
LEFT JOIN first_fraud f ON c.cc_num = f.cc_num
LEFT JOIN after_first_fraud a ON c.cc_num = a.cc_num
