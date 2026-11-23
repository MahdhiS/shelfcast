select
    date,
    store_nbr,
    item_nbr,
    unit_sales,
    onpromotion
from {{ source('raw', 'train') }}