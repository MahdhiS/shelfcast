{{ config(
    indexes=[
        {'columns': ['store_nbr', 'item_nbr', 'date']}
    ]
) }}

-- One row per store, item and day with sales (the grain of train.csv).
-- Facts hold keys and measures only: descriptions come from the dimensions.
-- Kept as recorded, Week 2 decides:
--   returns stay negative (DI-14)
--   onpromotion NULL = not recorded before 2014-04-01 (DI-13)
--   days with zero sales have no row (DI-11)
-- Index: fast lookups of one store-item's history (Week 2 features, the API).

select
    date,
    store_nbr,
    item_nbr,
    unit_sales,
    onpromotion
from {{ ref('stg_train') }}