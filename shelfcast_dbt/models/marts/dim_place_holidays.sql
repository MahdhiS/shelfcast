-- Regional and local holidays: one row per date per place (province or city).
-- National holidays are in dim_date.
-- Day 9 joins Regional rows through a store's state, Local rows through its city.

select
    date,
    locale,
    locale_name,
    is_holiday,
    is_additional,
    is_bridge,
    is_work_day,
    is_event
from {{ ref('int_holidays_squashed') }}
where locale in ('Regional', 'Local')