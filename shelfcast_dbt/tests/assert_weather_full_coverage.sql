-- Each city should have one row per day, 2013-01-01..2017-08-15 = 1,688 days
-- (load_weather.py checks the same before saving).
-- Returns any city with missing or duplicated days.

select
    city,
    count(*) as n_rows,
    count(distinct time) as n_days
from {{ source('raw', 'weather_daily') }}
group by city
having count(*) <> 1688
    or count(distinct time) <> 1688