{{ config(
    indexes=[
      {'columns': ['cc_num', 'ts']},
      {'columns': ['ts']},
      {'columns': ['is_fraud']}
    ]
) }}

SELECT
    trans_num,
    cc_num::numeric::bigint::text                       AS cc_num,
    ENCODE(SHA256(convert_to(cc_num::numeric::bigint::text,'UTF8')), 'hex') AS cc_hash,

    -- time: source of truth is trans_date + trans_time (unix_time is kept but not relied on)
    (trans_date || ' ' || trans_time)::timestamp         AS ts,
    trans_date::date                                     AS trans_date,
    unix_time::numeric::bigint                           AS unix_ts,

    -- merchant and category
    REPLACE(merchant, 'fraud_', '')                      AS merchant,
    category,
    -- channel, inferred from the category suffix. NULL on purpose for categories
    -- that carry no suffix (entertainment, food_dining, health_fitness, home,
    -- kids_pets, personal_care, travel) - the channel is genuinely unknown there,
    -- so NULL is the honest value rather than defaulting them to in-person.
    CASE WHEN RIGHT(category, 4) = '_net' THEN true
         WHEN RIGHT(category, 4) = '_pos' THEN false
         END                                             AS is_online,

    -- money and target
    amt::numeric(12,2)                                   AS amt,
    (is_fraud::numeric = 1)                              AS is_fraud,

    -- customer
    gender,
    dob::date                                            AS dob,
    EXTRACT(YEAR FROM AGE(trans_date::date, dob::date))::int AS age_at_txn,
    CASE
        WHEN EXTRACT(YEAR FROM AGE(trans_date::date, dob::date)) < 30 THEN '18-29'
        WHEN EXTRACT(YEAR FROM AGE(trans_date::date, dob::date)) < 45 THEN '30-44'
        WHEN EXTRACT(YEAR FROM AGE(trans_date::date, dob::date)) < 60 THEN '45-59'
        ELSE '60+'
    END                                                  AS age_bucket,
    job,
    profile,

    -- geography
    city,
    state,
    LPAD(SPLIT_PART(zip, '.', 1), 5, '0')                AS zip,
    city_pop::numeric::int                               AS city_pop,
    lat::float                                           AS cust_lat,
    long_::float                                         AS cust_long,
    merch_lat::float                                     AS merch_lat,
    merch_long::float                                    AS merch_long,

    -- time-based split label, used instead of source_file. Chronological, so no
    -- future information leaks into train: train <= 2020-12-31, valid <= 2021-06-30,
    -- test is everything after.
    CASE
        WHEN trans_date::date <= DATE '2020-12-31' THEN 'train'
        WHEN trans_date::date <= DATE '2021-06-30' THEN 'valid'
        ELSE 'test'
    END                                                  AS split_period

FROM {{ source('raw', 'raw_transactions') }}
WHERE trans_num IS NOT NULL
