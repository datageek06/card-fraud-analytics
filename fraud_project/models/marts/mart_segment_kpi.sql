select
    to_char(trans_date, 'YYYY-MM') as month,
    date_trunc('month', trans_date)::date as month_start,

    gender,
    age_bucket,
    category,
    count(distinct trans_num) as cnt_transactions,
    sum(amt) as total_amount,
    COUNT(*) FILTER (WHERE is_fraud) as cnt_fraud,
    sum(case when is_fraud then amt else 0 end) as fraud_amount,

    round(
        COUNT(*) FILTER (WHERE is_fraud) * 1.0 /
        nullif(count(distinct trans_num), 0),
    5) as fraud_share
from {{ ref('fact_transactions') }}
group by 1, 2, 3, 4, 5
