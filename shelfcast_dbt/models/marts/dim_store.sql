select
    stores.store_nbr,
    stores.city,
    stores.state,
    stores.store_type,
    stores.store_cluster,
    coordinates.latitude,
    coordinates.longitude
from {{ ref('stg_stores') }} as stores
left join {{ ref('stg_city_coordinates') }} as coordinates
    on stores.city = coordinates.city