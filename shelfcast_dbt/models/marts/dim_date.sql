-- One row per calendar day, 2013-01-01 to 2017-08-31.
-- Only things known in advance: calendar, paydays, national holidays.

with days as (

    -- end_date is NOT included, so 2017-09-01 makes 2017-08-31 the last day
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2013-01-01' as date)",
        end_date="cast('2017-09-01' as date)"
    ) }}

),

calendar as (

    select
        cast(date_day as date) as date,
        extract(year from date_day) as year,
        extract(month from date_day) as month,
        extract(day from date_day) as day_of_month,
        -- 1 = Monday ... 7 = Sunday (ISO). Postgres and Databricks name this differently.
        {% if target.type == 'postgres' %}
        extract(isodow from date_day) as day_of_week,
        {% else %}
        extract(dayofweek_iso from date_day) as day_of_week,
        {% endif %}
        -- used only to find the last day of the month (tomorrow is the 1st)
        extract(day from {{ dbt.dateadd('day', 1, 'date_day') }}) as tomorrow_day_of_month
    from days

),

national_holidays as (

    select *
    from {{ ref('int_holidays_squashed') }}
    where locale = 'National'

)

select
    calendar.date,
    calendar.year,
    calendar.month,
    calendar.day_of_month,
    calendar.day_of_week,
    calendar.day_of_week in (6, 7) as is_weekend,
    -- public-sector wages are paid on the 15th and the last day of the month (Kaggle notes)
    calendar.day_of_month = 15 or calendar.tomorrow_day_of_month = 1 as is_payday,
    -- days with no national holiday row get false, not NULL
    coalesce(national_holidays.is_holiday, false) as is_national_holiday,
    coalesce(national_holidays.is_additional, false) as is_national_additional,
    coalesce(national_holidays.is_bridge, false) as is_national_bridge,
    coalesce(national_holidays.is_work_day, false) as is_national_work_day,
    coalesce(national_holidays.is_event, false) as is_national_event
from calendar
left join national_holidays
    on calendar.date = national_holidays.date