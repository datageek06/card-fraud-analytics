-- Ищет аномальные транзакции, которые могли проскочить очистку
SELECT 
    trans_num,
    amt
FROM {{ ref('fact_transactions') }}
WHERE amt <= 0