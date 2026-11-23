select
    date,
    store_nbr,
    transactions as transaction_count
from {{ source('raw', 'transactions') }}