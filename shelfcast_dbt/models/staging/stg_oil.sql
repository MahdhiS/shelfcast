select
    date,
    dcoilwtico as oil_price
from {{ source('raw', 'oil') }}