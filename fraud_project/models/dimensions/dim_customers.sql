SELECT 
    cc_num,
    MAX(cc_hash) as cc_hash,

    MIN(gender) AS gender,
    MIN(dob) AS dob,

    MIN(city) AS city,
    MIN(state) AS state,
    MIN(zip) AS zip,
    MIN(city_pop) AS city_pop,
    MIN(profile) AS profile,

    MIN(ts) AS first_purchase,
    MAX(ts) AS last_purchase,

    COUNT(trans_num) AS cnt_transactions,
    SUM(amt) AS total_amount,
    ROUND(AVG(amt), 2) AS avg_amount,

    CASE
        WHEN SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) > 0
            THEN TRUE
        ELSE FALSE
    END AS has_fraud_ever,

    SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) AS fraud_cnt,
    SUM(CASE WHEN is_fraud THEN amt ELSE 0 END) AS fraud_amount
FROM {{ ref('stg_transactions') }}
WHERE cc_num is NOT NULL
GROUP BY cc_num