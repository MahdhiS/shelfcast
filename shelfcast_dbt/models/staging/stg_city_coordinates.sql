select
    city,
    state,
    geonames_name,
    feature_code,
    latitude,
    longitude
from {{ source('raw', 'city_coordinates') }}