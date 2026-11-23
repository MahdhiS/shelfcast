-- Day 1 finding: onpromotion is NULL for every row before 2014-04-01
-- (promotions weren't recorded yet) and never NULL from that date on.
-- Returns any date that breaks the pattern.

select
    date,
    count(*) as n_rows
from {{ source('raw', 'train') }}
where (date < '2014-04-01' and onpromotion is not null)
   or (date >= '2014-04-01' and onpromotion is null)
group by date