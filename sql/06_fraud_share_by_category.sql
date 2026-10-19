SELECT
    category,
    SUM(cnt_transactions) AS cnt_transactions,
    SUM(fraud_cnt) AS fraud_cnt,
    ROUND(SUM(fraud_amount)::numeric, 2) AS fraud_amount,
 
    -- how often fraud happens here
    ROUND(SUM(fraud_cnt) * 100.0 / SUM(cnt_transactions), 3) AS fraud_rate_pct,
    -- what share of all fraud EVENTS this category holds
    ROUND(SUM(fraud_cnt) * 100.0 / SUM(SUM(fraud_cnt)) OVER (), 2) AS pct_of_fraud_count,
    -- what share of all fraud MONEY this category holds
    ROUND(SUM(fraud_amount) * 100.0 / SUM(SUM(fraud_amount)) OVER (), 2) AS pct_of_fraud_loss
FROM public_marts.mart_merchant_risk
GROUP BY category
ORDER BY pct_of_fraud_loss DESC;

-- INSIGHT:
-- Online shopping (shopping_net) is the riskiest category by rate, driving 32.2% of fraud losses despite being only 7% of transactions. 
-- Conversely, grocery stores (grocery_pos) have a low fraud rate but high volume, accounting for 22% of total fraud events.