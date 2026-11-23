select
    city,
    time as date,
    temperature_2m_max as temp_max,
    temperature_2m_min as temp_min,
    precipitation_sum as precipitation
from {{ source('raw', 'weather_daily') }}