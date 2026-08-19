SELECT
    category,
    SUM(cnt_transactions)                                                  AS cnt_transactions,
    SUM(fraud_cnt)                                                         AS fraud_cnt,
    ROUND(SUM(fraud_amount)::numeric, 2)                                   AS fraud_amount,
 
    -- how often fraud happens here
    ROUND(SUM(fraud_cnt) * 100.0 / SUM(cnt_transactions), 3)               AS fraud_rate_pct,
    -- what share of all fraud EVENTS this category holds
    ROUND(SUM(fraud_cnt) * 100.0 / SUM(SUM(fraud_cnt)) OVER (), 2)         AS pct_of_fraud_count,
    -- what share of all fraud MONEY this category holds
    ROUND(SUM(fraud_amount) * 100.0 / SUM(SUM(fraud_amount)) OVER (), 2)   AS pct_of_fraud_loss
FROM public_marts.mart_merchant_risk
GROUP BY category
ORDER BY pct_of_fraud_loss DESC;

-- INSIGHT:
-- shopping_net is ~7% of all transactions but 21.5% of fraud events and
-- 32.2% of fraud dollar losses -- the riskiest category by rate. grocery_pos
-- tells the opposite story: a modest 0.83% fraud rate, but its sheer volume
-- makes it 22% of all fraud *events*. "Highest rate" and "highest absolute
-- loss/volume" are different questions, and both should drive where
-- monitoring effort goes.