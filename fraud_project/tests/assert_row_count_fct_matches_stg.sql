WITH stg AS (
    SELECT COUNT(1) AS stg_count 
    FROM {{ ref('stg_transactions') }}
),
fct AS (
    SELECT COUNT(1) AS fct_count 
    FROM {{ ref('fact_transactions') }}
)

SELECT 
    stg.stg_count,
    fct.fct_count
FROM stg
CROSS JOIN fct
WHERE stg.stg_count != fct.fct_count
