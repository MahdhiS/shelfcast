-- Number of receipts per store per day.
-- A missing row means "not recorded", never zero (DI-09, DI-10), so gaps are not filled here.

select
    date,
    store_nbr,
    transaction_count
from {{ ref('stg_transactions') }}