-- Expected counts come from Day 1 profiling (CSV row counts)
-- and the Day 2-3 load checks (sql/raw_checks.sql, sql/weather_checks.sql).
-- Returns a row only for a table whose count is wrong.

select 'stores' as table_name, count(*) as row_count
from {{ source('raw', 'stores') }}
having count(*) <> 54

union all

select 'items', count(*)
from {{ source('raw', 'items') }}
having count(*) <> 4100

union all

select 'oil', count(*)
from {{ source('raw', 'oil') }}
having count(*) <> 1218

union all

select 'holidays_events', count(*)
from {{ source('raw', 'holidays_events') }}
having count(*) <> 350

union all

select 'transactions', count(*)
from {{ source('raw', 'transactions') }}
having count(*) <> 83488

union all

select 'train', count(*)
from {{ source('raw', 'train') }}
having count(*) <> 125497040

union all

select 'city_coordinates', count(*)
from {{ source('raw', 'city_coordinates') }}
having count(*) <> 22

union all

select 'weather_daily', count(*)
from {{ source('raw', 'weather_daily') }}
having count(*) <> 37136