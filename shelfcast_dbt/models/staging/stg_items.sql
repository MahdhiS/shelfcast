select
    item_nbr,
    -- DI-19: tidy family names, read inside-out:
    --   1. commas -> _   2. slashes -> _   3. spaces -> _   4. lowercase
    --   e.g. 'BREAD/BAKERY' -> 'bread_bakery'
    lower(replace(replace(replace(family, ',', '_'), '/', '_'), ' ', '_')) as family,
    class as item_class,
    perishable = 1 as is_perishable
from {{ source('raw', 'items') }}