SELECT 
    date,
    total_amount,
    fraud_amount
FROM {{ ref('mart_daily_kpi') }}
WHERE fraud_amount > total_amount
