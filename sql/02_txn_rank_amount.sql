WITH ranked AS (
    SELECT
        t.cc_num,
        f.session_no,
        t.amt,
        ROW_NUMBER() OVER (PARTITION BY t.cc_num, f.session_no ORDER BY t.ts) AS txn_rank
    FROM public_core.fact_transactions t
    JOIN public_marts.mart_fraud_sessions f
      ON  t.cc_num = f.cc_num
      AND t.ts    >= f.session_start
      AND t.ts    <= f.session_end
    WHERE t.is_fraud
)
SELECT
    txn_rank,
    COUNT(*)                                                                  AS sessions_reaching_rank,
    ROUND(AVG(amt)::numeric, 2)                                               AS avg_amount,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amt)::numeric, 2)       AS median_amount,
    ROUND(MIN(amt)::numeric, 2)                                               AS min_amount,
    ROUND(MAX(amt)::numeric, 2)                                               AS max_amount
FROM ranked
GROUP BY txn_rank
HAVING COUNT(*) >= 10
ORDER BY txn_rank;

-- INSIGHT:
-- Amounts inside a fraud session are not flat. Median amount climbs from
-- $304 on the 1st transaction of a session to ~$830 by the 8th-10th
-- transaction, then tapers off (few sessions run that long). This suggests a
-- "test charge, then escalate" pattern: fraudsters often start with a small
-- purchase to confirm the card still works before moving to larger charges.
-- Practical takeaway: a small charge on a card should not be dismissed as
-- low-risk if it's immediately followed by a rapid sequence of further charges.