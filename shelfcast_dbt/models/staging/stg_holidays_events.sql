select
    date,
    type as holiday_type,
    locale,
    locale_name,
    description,
    transferred
from {{ source('raw', 'holidays_events') }}