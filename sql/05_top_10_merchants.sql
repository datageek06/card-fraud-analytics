select
    merchant,
    category,
    cnt_transactions,
    fraud_cnt,
    fraud_rate,
    expected_loss_per_1000,
    has_enough_volume
from public_marts.mart_merchant_risk
where has_enough_volume
order by expected_loss_per_1000 desc
limit 10;

-- INSIGHT:
-- Online ("card-not-present") merchants account for 9 of the top 10 highest-risk sellers. 
-- Fraud is concentrated in a small group of online merchants rather than spread evenly across all businesses.