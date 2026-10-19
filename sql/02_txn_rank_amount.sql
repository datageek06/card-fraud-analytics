WITH ranked AS (
    SELECT
        t.cc_num,
        f.session_no,
        t.amt,
        ROW_NUMBER() OVER (PARTITION BY t.cc_num, f.session_no ORDER BY t.ts) AS txn_rank
    FROM public_core.fact_transactions t
    JOIN public_marts.mart_fraud_sessions f
      ON  t.cc_num = f.cc_num
      AND t.ts >= f.session_start
      AND t.ts <= f.session_end
    WHERE t.is_fraud
)
SELECT
    txn_rank,
    COUNT(*) AS sessions_reaching_rank,
    ROUND(AVG(amt)::numeric, 2) AS avg_amount,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amt)::numeric, 2) AS median_amount,
    ROUND(MIN(amt)::numeric, 2) AS min_amount,
    ROUND(MAX(amt)::numeric, 2) AS max_amount
FROM ranked
GROUP BY txn_rank
HAVING COUNT(*) >= 10
ORDER BY txn_rank;

-- INSIGHT:
-- Fraudsters use a "test and escalate" pattern: they start with a small test charge to check if the card works, 
-- then rapidly increase transaction amounts for subsequent purchases.