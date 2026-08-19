{{ config(
    materialized='table',
    indexes=[
      {'columns': ['cc_num', 'ts']},
      {'columns': ['ts']},
      {'columns': ['trans_num'], 'unique': true}
    ]
)}}

-- One row per transaction. Adds derived time, distance and amount-band columns
-- on top of stg_transactions; no filtering or aggregation beyond dropping NULL ids.

SELECT
    trans_num,
    cc_num,
    ts,
    EXTRACT(HOUR from ts) as hour,

    -- NOTE ON ENCODING: this is Postgres DOW, so 0=Sunday .. 6=Saturday.
    -- dim_date.day_of_week uses ISODOW instead (1=Monday .. 7=Sunday) - the two
    -- are deliberately different and must not be joined to each other. Join on
    -- dim_date.day_of_week_pg, which carries this same DOW convention.
    -- This column is a model feature (see data/processed/features.json), so its
    -- encoding is frozen: changing it would invalidate the saved model artifact.
    EXTRACT(DOW from ts) as day_of_week,

    -- unambiguous label for BI - identical text in dim_date, so charts never
    -- have to show a bare number whose convention the reader has to guess
    TRIM(TO_CHAR(ts, 'Day')) as day_name,
    (EXTRACT(ISODOW from ts) IN (6, 7)) as is_weekend,

    trans_date,
    merchant,
    category,
    gender,
    dob,
    age_at_txn,
    age_bucket,
    job,
    city,
    state,
    zip,
    city_pop,
    cust_lat,
    cust_long,
    merch_lat,
    merch_long,

    -- great-circle distance between customer home and merchant (Haversine, km).
    -- EDA found no relationship with fraud (chi-square p = 0.63) and SHAP agrees
    -- it barely moves the model - kept because that negative result is a finding.
    ROUND(6371 * 2 * ASIN(SQRT(
        POWER(SIN(RADIANS(merch_lat - cust_lat) / 2), 2) +
        COS(RADIANS(cust_lat)) * COS(RADIANS(merch_lat)) *
        POWER(SIN(RADIANS(merch_long - cust_long) / 2), 2)
    ))) AS distance_km,

    amt,
    CASE
        WHEN amt < 10 THEN 'Under 10'
        WHEN amt >= 10 AND amt < 50 THEN '10-50'
        WHEN amt >= 50 AND amt < 200 THEN '50-200'
        WHEN amt >= 200 AND amt < 1000 THEN '200-1000'
        WHEN amt >= 1000 AND amt < 2500 THEN '1000-2500'
        WHEN amt >= 2500 AND amt < 5000 THEN '2500-5000'
        WHEN amt >= 5000 AND amt < 10000 THEN '5000-10000'
        ELSE '10000+'
    END as amt_bucket,
    split_period,
    is_fraud
FROM {{ ref('stg_transactions') }}
where trans_num IS NOT NULL
