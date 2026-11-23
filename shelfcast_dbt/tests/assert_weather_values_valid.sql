-- Physical sanity rules (sql/weather_checks.sql, Day 3):
-- the day's minimum can't be above its maximum, and rain can't be negative.

select *
from {{ source('raw', 'weather_daily') }}
where temperature_2m_min > temperature_2m_max
   or precipitation_sum < 0