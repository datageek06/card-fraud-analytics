SELECT
    d.date,
    COUNT(f.trans_num) AS cnt_transactions,
    COALESCE(SUM(f.amt), 0) AS total_amount,
    SUM(CASE WHEN f.is_fraud THEN 1 ELSE 0 END) AS cnt_fraud,
    COALESCE(SUM(CASE WHEN f.is_fraud THEN f.amt ELSE 0 END), 0) AS fraud_amount,

    ROUND(SUM(CASE WHEN f.is_fraud THEN 1 ELSE 0 END) * 1.0 / NULLIF(COUNT(f.trans_num), 0), 5) AS fraud_percentage,

    -- share of daily dollars that were fraudulent, in basis points
    ROUND(SUM(CASE WHEN f.is_fraud THEN f.amt ELSE 0 END) * 10000.0 / NULLIF(SUM(f.amt), 0), 2) AS fraud_share,

    ROUND(AVG(CASE WHEN NOT f.is_fraud THEN f.amt END), 2) AS avg_not_fraud_amount,
    ROUND(AVG(CASE WHEN f.is_fraud THEN f.amt END), 2) AS avg_fraud_amount
FROM {{ ref('dim_date') }} d
LEFT JOIN {{ ref('fact_transactions') }} f
    ON d.date = f.trans_date
GROUP BY d.date
ORDER BY d.date
