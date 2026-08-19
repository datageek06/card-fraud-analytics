SELECT
    merchant,

    MIN(category) as category,

    MIN(ts) AS first_transaction,
    MAX(ts) AS last_transaction,

    COUNT(trans_num) AS cnt_transactions,
    SUM(amt) AS total_amount,
    ROUND(AVG(amt), 2) AS avg_amount,

    SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) AS fraud_cnt,
    SUM(CASE WHEN is_fraud THEN amt ELSE 0 END) AS fraud_amount,
    ROUND(AVG(CASE WHEN is_fraud THEN amt END), 2) AS avg_fraud_amount
from {{ ref('stg_transactions') }}
GROUP BY merchant