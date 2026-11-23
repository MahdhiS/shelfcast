-- Key of transactions = date + store_nbr (Day 1 profiling).
-- Returns any store-day that appears more than once.

select
    date,
    store_nbr,
    count(*) as n_rows
from {{ source('raw', 'transactions') }}
group by date, store_nbr
having count(*) > 1