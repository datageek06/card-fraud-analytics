{{ config(
    materialized='table',
    indexes=[
      {'columns': ['cc_num', 'ts']}
    ]
) }}

select
    trans_num,
    cc_num,
    ts,
    extract(epoch from (ts - lag(ts) over w_prev)) as sec_since_last_txn,
    case when lag(ts) over w_prev is null then true else false end as is_first_txn,

    count(trans_num) over w1h as cnt_txn_1h,
    count(trans_num) over w24h as cnt_txn_24h,
    count(trans_num) over w7d as cnt_txn_7d,

    sum(amt) over w24h as sum_amount_24h,

    ROUND(
        (amt / NULLIF(AVG(amt) OVER w30d, 0))::numeric,
        4
    ) AS ratio_to_30d_avg,

    (
        SELECT COUNT(DISTINCT t2.merchant)
        FROM {{ ref('stg_transactions') }} t2
        WHERE t2.cc_num = t1.cc_num
          AND t2.ts >= t1.ts - INTERVAL '24 hours'
          AND t2.ts < t1.ts
    ) AS cnt_distinct_merchants_24h

from {{ ref('stg_transactions') }} t1


window
    w_prev as (
        partition by cc_num
        order by ts
    ),
    w1h as (
        partition by cc_num
        order by ts
        range between interval '1 hour' preceding and interval '1 second' preceding
    ),
    w24h as (
        partition by cc_num
        order by ts
        range between interval '24 hours' preceding and interval '1 second' preceding
    ),
    w7d as (
        partition by cc_num
        order by ts
        range between interval '7 days' preceding and interval '1 second' preceding
    ),
    w30d as (
        partition by cc_num
        order by ts
        range between interval '30 days' preceding and interval '1 second' preceding
    )

-- select
--     t1.cc_num,
--     t1.ts,
--     t2.ts,
--     t1.merchant,
--     t2.merchant
-- from stg_transactions t1
-- left join stg_transactions t2
--     on t2.cc_num = t1.cc_num
--           AND t2.ts >= t1.ts - INTERVAL '24 hours'
--             AND t2.ts < t1.ts
-- order by cc_num, t1.ts