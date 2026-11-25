-- Daily weather per city (ERA5 via Open-Meteo): one row per city per day.
-- Measured each day, so a fact table (periodic snapshot), like oil.
-- DI-22: rain amounts are biased in some cities, use relative rain features, not raw mm.

select
    city,
    date,
    temp_max,
    temp_min,
    precipitation
from {{ ref('stg_weather_daily') }}