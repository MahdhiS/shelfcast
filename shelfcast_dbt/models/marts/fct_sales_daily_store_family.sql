-- One row per date per store per product family.
-- A summary of fct_sales: analysis reads about 3M rows instead of 125M.
-- Kept as recorded, like fct_sales: returns stay negative (DI-14).

with sales_with_family as (

    -- each sales row gets its item's family (family names tidied in stg_items, DI-19)
    select
        sales.date,
        sales.store_nbr,
        items.family,
        sales.unit_sales,
        sales.onpromotion
    from {{ ref('fct_sales') }} as sales
    left join {{ ref('dim_item') }} as items
        on sales.item_nbr = items.item_nbr

)

select
    date,
    store_nbr,
    family,
    -- exact decimal sum: real loses small amounts on big totals
    sum(cast(unit_sales as {{ dbt.type_numeric() }})) as unit_sales,
    -- number of items with a sales row (a sale or a return)
    count(*) as items_recorded,
    -- true = 1, false = 0, NULL stays NULL: before 2014-04-01 the result is NULL (DI-13)
    sum(cast(onpromotion as integer)) as items_on_promotion
from sales_with_family
group by
    date,
    store_nbr,
    family