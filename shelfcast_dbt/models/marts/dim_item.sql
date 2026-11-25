select
    item_nbr,
    family,
    item_class,
    is_perishable
from {{ ref('stg_items') }}