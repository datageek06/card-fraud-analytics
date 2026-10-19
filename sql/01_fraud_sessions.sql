with gapped as (
    select cc_num, amt, merchant, category, ts,
           ts - lag(ts) over(partition by cc_num order by ts) as gap
    from public_core.fact_transactions
    where is_fraud
), flagged as (
    select
        *,
        case
            when gap is null or gap > interval '24 hours' then 1
            else 0
        end as is_new_session
    from gapped
), numbered as (
    select *,
        sum(is_new_session) over(
           partition by cc_num
           order by ts
           rows unbounded preceding
        ) as session_no
    from flagged
)

select
    cc_num,
    session_no,
    count(*) as txn_in_session,
    min(ts) as session_start,
    max(ts) as session_end,
    max(ts) - min(ts) as duration,
    round(extract(epoch from (max(ts) - min(ts))/60 )) as duration_min,
    sum(amt) as session_amount,
    min(amt) as min_amount,
    max(amt) as max_amount,
    count(distinct merchant) as merchant_cnt
from numbered
group by cc_num, session_no
order by cc_num, session_no;

-- INSIGHT:
-- Fraud happens in rapid clusters across multiple merchants rather than single isolated events. 
-- Scammers hit a compromised card repeatedly within a short window.





WITH fraud_gaps AS (
    SELECT
        cc_num,
        ts,
        amt,
        EXTRACT(EPOCH FROM (ts - LAG(ts) OVER(PARTITION BY cc_num ORDER BY ts))) / 3600.0 AS hours_since_prev_fraud
    FROM public_core.fact_transactions
    WHERE is_fraud
),
threshold_tests AS (
    SELECT
        hours_since_prev_fraud,
        CASE WHEN hours_since_prev_fraud IS NULL OR hours_since_prev_fraud > 1 THEN 1 ELSE 0 END AS flag_1h,
        CASE WHEN hours_since_prev_fraud IS NULL OR hours_since_prev_fraud > 6 THEN 1 ELSE 0 END AS flag_6h,
        CASE WHEN hours_since_prev_fraud IS NULL OR hours_since_prev_fraud > 12 THEN 1 ELSE 0 END AS flag_12h,
        CASE WHEN hours_since_prev_fraud IS NULL OR hours_since_prev_fraud > 24 THEN 1 ELSE 0 END AS flag_24h,
        CASE WHEN hours_since_prev_fraud IS NULL OR hours_since_prev_fraud > 48 THEN 1 ELSE 0 END AS flag_48h,
        CASE WHEN hours_since_prev_fraud IS NULL OR hours_since_prev_fraud > 168 THEN 1 ELSE 0 END AS flag_168h
    FROM fraud_gaps
)
SELECT '1 hour' AS threshold, SUM(flag_1h) AS total_series_count FROM threshold_tests
UNION ALL
SELECT '6 hours', SUM(flag_6h) FROM threshold_tests
UNION ALL
SELECT '12 hours', SUM(flag_12h) FROM threshold_tests
UNION ALL
SELECT '24 hours', SUM(flag_24h) FROM threshold_tests
UNION ALL
SELECT '48 hours', SUM(flag_48h) FROM threshold_tests
UNION ALL
SELECT '168 hours (1 week)', SUM(flag_168h) FROM threshold_tests;