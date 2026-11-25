select
    item_nbr,
    -- DI-19: tidy family names, e.g. 'LIQUOR,WINE,BEER' -> 'liquor_wine_beer'
    lower(replace(replace(replace(family, ',', '_'), '/', '_'), ' ', '_')) as family,
    class as item_class,
    perishable = 1 as is_perishable
from {{ source('raw', 'items') }}