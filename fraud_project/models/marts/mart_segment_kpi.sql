-- Monthly fraud KPIs cut by customer segment and spend category.
-- Grain: one row per month x gender x age_bucket x category.

select
    to_char(trans_date, 'YYYY-MM') as month,

    -- real date alongside the text label, so BI tools can relate this mart to
    -- dim_date.month_start directly instead of parsing the string
    date_trunc('month', trans_date)::date as month_start,

    gender,
    age_bucket,
    category,
    count(distinct trans_num) as cnt_transactions,
    sum(amt) as total_amount,
    COUNT(*) FILTER (WHERE is_fraud) as cnt_fraud,
    sum(case when is_fraud then amt else 0 end) as fraud_amount,

    -- 0-1 ratio. Do not average this across rows in a BI tool - re-derive it from
    -- cnt_fraud / cnt_transactions at whatever grain is being displayed.
    round(
        COUNT(*) FILTER (WHERE is_fraud) * 1.0 /
        nullif(count(distinct trans_num), 0),
    5) as fraud_share
from {{ ref('fact_transactions') }}
group by 1, 2, 3, 4, 5
