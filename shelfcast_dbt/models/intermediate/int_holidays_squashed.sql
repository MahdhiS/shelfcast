-- One row per date per place, with one true/false flag per type of day.
-- Used by dim_date (national rows) and the regional/local holidays table.

select
    date,
    locale,
    locale_name,
    bool_or(holiday_type in ('Holiday', 'Transfer')) as is_holiday,
    bool_or(holiday_type = 'Additional') as is_additional,
    bool_or(holiday_type = 'Bridge') as is_bridge,
    bool_or(holiday_type = 'Work Day') as is_work_day,
    bool_or(holiday_type = 'Event') as is_event
from {{ ref('stg_holidays_events') }}
-- DI-02: a transferred holiday was not celebrated on this date (normal working day).
-- The day it was really celebrated is its 'Transfer' row, which we keep.
where transferred = false
-- DI-01: squash duplicate date + place rows into one
group by date, locale, locale_name