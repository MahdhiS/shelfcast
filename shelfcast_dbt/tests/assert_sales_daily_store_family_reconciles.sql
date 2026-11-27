-- Reconciliation: the summary must add up to the detail exactly.
-- Returns a row (= test fails) if fct_sales_daily_store_family lost or invented any sales.

with detail_totals as (

    -- the same exact decimal cast as the model, so both sides are summed the same way
    select
        count(*) as row_count,
        sum(cast(unit_sales as {{ dbt.type_numeric() }})) as total_units
    from {{ ref('fct_sales') }}

),

summary_totals as (

    select
        sum(items_recorded) as row_count,
        sum(unit_sales) as total_units
    from {{ ref('fct_sales_daily_store_family') }}

)

select
    detail_totals.row_count as detail_row_count,
    summary_totals.row_count as summary_row_count,
    detail_totals.total_units as detail_total_units,
    summary_totals.total_units as summary_total_units
from detail_totals
cross join summary_totals
where detail_totals.row_count <> summary_totals.row_count
    or detail_totals.total_units <> summary_totals.total_units