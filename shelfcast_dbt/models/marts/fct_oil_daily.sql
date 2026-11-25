-- One row per calendar day with the WTI oil price, last known price carried forward.
-- Kept apart from dim_date: oil is measured each day, not known in advance (DI-08).

with oil_on_day as (

    -- weekends and market holidays have no price yet (DI-06, DI-07)
    select
        dates.date,
        oil.oil_price
    from {{ ref('dim_date') }} as dates
    left join {{ ref('stg_oil') }} as oil
        on dates.date = oil.date

),

oil_groups as (

    -- each known price starts a new group; the empty days after it join that group
    select
        date,
        oil_price,
        count(oil_price) over (order by date) as oil_group
    from oil_on_day

)

-- every day in a group gets the group's one known price (last known price)
select
    date,
    max(oil_price) over (partition by oil_group) as oil_price
from oil_groups