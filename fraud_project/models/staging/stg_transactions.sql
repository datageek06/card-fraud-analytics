{{ config(
    indexes=[
      {'columns': ['cc_num', 'ts']},
      {'columns': ['ts']},
      {'columns': ['is_fraud']}
    ]
) }}

SELECT
    trans_num,
    cc_num::numeric::bigint::text AS cc_num,
    ENCODE(SHA256(convert_to(cc_num::numeric::bigint::text,'UTF8')), 'hex') AS cc_hash,

    (trans_date || ' ' || trans_time)::timestamp AS ts,
    trans_date::date AS trans_date,
    unix_time::numeric::bigint AS unix_ts,

    REPLACE(merchant, 'fraud_', '') AS merchant,
    category,
    CASE WHEN RIGHT(category, 4) = '_net' THEN true
         WHEN RIGHT(category, 4) = '_pos' THEN false
         END AS is_online,

    amt::numeric(12,2) AS amt,
    (is_fraud::numeric = 1) AS is_fraud,

    -- customer
    gender,
    dob::date AS dob,
    EXTRACT(YEAR FROM AGE(trans_date::date, dob::date))::int AS age_at_txn,
    CASE
        WHEN EXTRACT(YEAR FROM AGE(trans_date::date, dob::date)) < 30 THEN '18-29'
        WHEN EXTRACT(YEAR FROM AGE(trans_date::date, dob::date)) < 45 THEN '30-44'
        WHEN EXTRACT(YEAR FROM AGE(trans_date::date, dob::date)) < 60 THEN '45-59'
        ELSE '60+'
    END AS age_bucket,
    job,
    profile,

    -- geography
    city,
    state,
    LPAD(SPLIT_PART(zip, '.', 1), 5, '0') AS zip,
    city_pop::numeric::int AS city_pop,
    lat::float AS cust_lat,
    long_::float AS cust_long,
    merch_lat::float AS merch_lat,
    merch_long::float AS merch_long,


    CASE
        WHEN trans_date::date <= DATE '2020-12-31' THEN 'train'
        WHEN trans_date::date <= DATE '2021-06-30' THEN 'valid'
        ELSE 'test'
    END AS split_period

FROM {{ source('raw', 'raw_transactions') }}
WHERE trans_num IS NOT NULL
