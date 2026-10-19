{{ config(
    materialized='table',
    indexes=[
      {'columns': ['category'], 'unique': true}
    ]
) }}

SELECT
    category,
    
    INITCAP(REPLACE(REPLACE(category, '_net', ''), '_pos', '')) 
        || CASE 
            WHEN category LIKE '%_net' THEN ' (Online)'
            WHEN category LIKE '%_pos' THEN ' (In-person)'
            ELSE ''
           END AS category_label,

    CASE 
        WHEN category LIKE '%_net' THEN 'Online'
        WHEN category LIKE '%_pos' THEN 'In-person'
        ELSE 'Unknown'
    END AS channel,

    CASE 
        WHEN category LIKE '%_net' THEN TRUE
        WHEN category LIKE '%_pos' THEN FALSE
    END AS is_online,

    COUNT(*) AS cnt_transactions,
    SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) AS fraud_cnt,
    SUM(CASE WHEN is_fraud THEN amt ELSE 0 END) AS fraud_amount,
    CAST(SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) AS FLOAT) / NULLIF(COUNT(*), 0) AS fraud_rate

FROM {{ ref('stg_transactions') }}
GROUP BY category