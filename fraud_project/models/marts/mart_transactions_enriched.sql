{{ config(
    materialized='table',
    indexes=[
      {'columns': ['cc_num', 'ts']},
      {'columns': ['is_fraud']}
    ]
) }}

-- One row per transaction, ready to pull into Python for EDA.
-- Joins fact_transactions with mart_card_velocity's point-in-time-safe
-- behavioral features (each window looks only at transactions strictly
-- before ts, so nothing here uses information from the future).

select
    f.trans_num,
    f.cc_num,
    f.ts,
    f.trans_date,
    f.hour,
    f.day_of_week,
    f.merchant,
    f.category,
    f.gender,
    f.age_at_txn,
    f.age_bucket,
    f.job,
    f.city,
    f.state,
    f.zip,
    f.city_pop,
    f.distance_km,
    f.amt,
    f.amt_bucket,
    f.split_period,
    f.is_fraud,

    v.sec_since_last_txn,
    v.is_first_txn,
    v.cnt_txn_1h,
    v.cnt_txn_24h,
    v.cnt_txn_7d,
    v.sum_amount_24h,
    v.ratio_to_30d_avg,
    v.cnt_distinct_merchants_24h

from {{ ref('fact_transactions') }} f
left join {{ ref('mart_card_velocity') }} v
    on f.trans_num = v.trans_num
