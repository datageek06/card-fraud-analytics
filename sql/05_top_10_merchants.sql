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
-- 9 of the top 10 merchants by expected loss per 1000 transactions are
-- "_net" (card-not-present / online) merchants, almost all in shopping_net.
-- Fraud risk is concentrated in a small set of online merchants rather than
-- spread evenly across the merchant base -- useful for merchant-level risk
-- scoring or targeted monitoring instead of blanket rules.