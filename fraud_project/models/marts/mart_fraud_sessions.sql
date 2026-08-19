with gapped as (
    select cc_num, amt, merchant, category, ts,
           ts - lag(ts) over(partition by cc_num order by ts) as gap
    from {{ ref('fact_transactions') }}
    where is_fraud
), flagged as (
    select
        *,
        case
            when gap is null or gap > interval '24 hours' then 1
            else 0
        end as is_new_session
    from gapped
), numbered as (
    select *,
        sum(is_new_session) over(
           partition by cc_num
           order by ts
           rows unbounded preceding
        ) as session_no
    from flagged
)

select
    cc_num,
    session_no,
    count(*) as txn_in_session,
    min(ts) as session_start,
    max(ts) as session_end,
    max(ts) - min(ts) as duration,
    round(extract(epoch from (max(ts) - min(ts))/60 )) as duration_min,
    sum(amt) as session_amount,
    min(amt) as min_amount,
    max(amt) as max_amount,
    count(distinct merchant) as merchant_cnt
from numbered
group by cc_num, session_no