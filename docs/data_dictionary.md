# Shelfcast data dictionary

Source labels:
- Official: Kaggle competition data page (favorita-grocery-sales-forecasting)
- Observed: our own profiling (notebooks/01_profiling.ipynb)
- Unknown: not documented anywhere, do not assume meaning

## stores.csv
One row per store. Key: store_nbr. 54 rows, no nulls.

| column | dtype | meaning | source | notes |
|---|---|---|---|---|
| store_nbr | int | Store ID | Official | 54 unique values, one per row, so this is the key (Observed) |
| city | str | City the store is in | Official | 22 cities. Quito 18 stores, Guayaquil 8, 14 cities have only 1 (Observed) |
| state | str | State the store is in | Official | 16 states. These are Ecuador's provinces |
| type | str | Store type, values A–E | Unknown | Favorita never defined the letters |
| cluster | int | "Grouping of similar stores" | Official (meaning), Unknown (method) | 17 clusters. How "similar" was decided is not documented. Can check in EDA |


## items.csv
One row per item. Key: item_nbr. 4,100 rows, no nulls.
Hierarchy (checked): family → class → item.

| column | dtype | meaning | source | notes |
|---|---|---|---|---|
| item_nbr | int | Item ID | Official | 4,100 unique values in 4,100 rows, so one row per item. Large codes (e.g. 96995), not 1–4100, so it needs int32 later (Observed) |
| family | str | Product category, the top level of the hierarchy | Observed | Official page only names the column. 33 families. Largest: GROCERY I (1,334 items, ~33%), BEVERAGES (613), CLEANING (446). Long tail: HOME APPLIANCES, BABY CARE and BOOKS have 1 item each. Includes non-food families (e.g. LADIESWEAR, AUTOMOTIVE). Difference between GROCERY I and GROCERY II is not documented |
| perishable | int | 1 = perishable, 0 = not | Official (flag), Observed (values) | 986 of 4,100 items (~24%) are perishable.|
| class | int | Sub-category inside a family | Observed (structure), Unknown (names) | 337 classes, codes only, no names. Every class belongs to exactly 1 family (checked). First two digits (class // 100) map one-to-one to family (checked). Matches the standard retail "class" level, but Favorita never confirmed this |


Sources for the "class" interpretation: Oracle Retail Merchandising docs (class = level below department, rolls up to a single department).


## oil.csv
One row per weekday. Key: date. 1,218 rows.

| column | dtype | meaning | source | notes |
|---|---|---|---|---|
| date | str | Trading day | Official ("daily oil price") | 1,218 unique values in 1,218 rows, so this is the key (Observed). Weekdays only, Mon–Fri ~243–244 rows each. Weekends have no row. Range: 2013-01-01 to 2017-08-31 |
| dcoilwtico | float | WTI crude oil spot price, US dollars per barrel | Observed (column name matches FRED series DCOILWTICO, source: US EIA) | No null dates, but 43 null prices: 42 are US market holidays (NYSE calendar, including Good Friday and weekend holidays observed on the nearest weekday). 1 unexplained: 2017-07-03, an early-close day (market open until 1 p.m.), not a full holiday. Ecuador's oil is priced relative to WTI |

Sources: FRED series DCOILWTICO (https://fred.stlouisfed.org/series/DCOILWTICO), NYSE holiday calendars 2013–2017, EIA on WTI as the benchmark for South American crude.


## holidays_events.csv
One row per holiday or event (not per day). Key: date + locale_name + description (checked, 0 duplicates). 350 rows, no nulls.
Range: 2012-03-02 to 2017-12-26, so it extends before and after the sales data.
7 date + place pairs have two rows on the same day: Bridge + Additional (3), earthquake event + another event (3), Guayaquil 2016-07-24 Additional + Transfer (1).

| column | dtype | meaning | source | notes |
|---|---|---|---|---|
| date | str | Date of the holiday or event | Official | 312 unique dates in 350 rows, so not unique on its own |
| type | str | Kind of day | Official | Holiday 221, Event 56, Additional 51, Transfer 12, Bridge 5, Work Day 5. Transfer = the day a moved holiday was actually celebrated. Bridge = extra day off to make a long weekend. Work Day = a Saturday worked to pay back a bridge (before or after it). Additional = extra days around a holiday (e.g. Christmas Eve) |
| locale | str | Level the holiday applies to | Observed | National 174, Regional 24, Local 152 |
| locale_name | str | Place the holiday applies to | Observed | 24 values: Ecuador (National), a province (Regional) or a city (Local). Every value exactly matches a stores city, a stores state, or Ecuador (checked). Join: National → all stores, Regional → stores.state, Local → stores.city |
| description | str | Name of the holiday or event, in Spanish | Observed | 103 values. Traslado = moved, Puente = bridge, Recupero = make-up work day. -1 / +1 = days before / after a holiday. "Terremoto Manabi+N" = N days after the 2016-04-16 earthquake (Official note mentions the earthquake). Inconsistent: 2 Transfer rows (Cuenca 2017-04-13, Ibarra 2017-09-29) lack "Traslado" |
| transferred | bool | True = holiday officially falls here but was moved to another date | Official | 12 True. Each pairs with a type = Transfer row for the same place. Official: "more like a normal day than a holiday". Unexplained: Fundación de Guayaquil moved from 2016-07-25 (Mon) to 2016-07-24 (Sun) |


## transactions.csv
One row per store per day. Key: date + store_nbr (checked). 83,488 rows, no nulls.
Range: 2013-01-01 to 2017-08-15, the same as the sales data (Official: training timeframe only).

| column | dtype | meaning | source | notes |
|---|---|---|---|---|
| date | str | Day | Official | 1,682 unique dates. 6 days have no rows at all: Christmas 2013–2016, 2016-01-01, and 2016-01-03 (a Sunday, not a holiday, unexplained). Very few stores on New Year's Days (1–2). Unusually low on 2016-01-02 (36 stores), 2016-01-04 (14) and 2013-06-19 (43), unexplained |
| store_nbr | int | Store ID, links to stores.csv | Official | All 54 stores appear. Late openings: 20, 21, 22, 29, 36, 42, 53 (2013–2015) and 52 (2017-04-20, only 118 days). No store stops before 2017-08-15 |
| transactions | int | Number of sales transactions at that store that day | Official | 4,993 unique values |

## train.csv
One row per store × item × day **with sales**. Zero-sales days have no row (Official).
Key: date + store_nbr + item_nbr (checked, 0 duplicates). 125,497,040 rows.
Range: 2013-01-01 to 2017-08-15. 1,684 days; only Christmas 2013–2016 have no rows.
Completeness: 1,684 days × 54 stores × 4,036 items = 367,017,696 possible rows; 34% exist. The rest mixes zero-sales days, stores not yet open and items not yet on sale.

| column | dtype | meaning | source | notes |
|---|---|---|---|---|
| id | int | Row number | Official | Unique for every row. Carries no information, kept in raw only |
| date | date | Day of the sales | Official | 2013-01-01 to 2017-08-15. 2016-01-01 has only 1,718 rows (New Year). 2016-01-02 to 01-04 have normal row counts (~100k), although transactions.csv is missing most stores on those days |
| store_nbr | int | Store ID, links to stores.csv | Official | All 54 stores appear |
| item_nbr | int | Item ID, links to items.csv | Official | 4,036 items sold, all present in items.csv (checked). 64 catalogue items never sold |
| unit_sales | float | Units sold that day. Can be a fraction for items sold by weight | Official | Median 4, 75% of rows ≤ 9, mean 8.55. 7,795 negative rows (returns, Official). 8,191,095 fractional rows (6.5%), all in weighed families: PRODUCE, MEATS, POULTRY, FROZEN FOODS, DELI, SEAFOOD, PREPARED FOODS, plus 2 GROCERY I items and 1 BREAD/BAKERY item. Extremes: max 89,440 (store 39, MEATS item 1976284, 2016-10-07: an item sold on only 25 days, always in the thousands); min −15,372 (store 18, BEVERAGES item 1166474, 2015-06-22: follows a 9,025 spike on 2015-06-19, item normally ~10/day; looks like a recording error, cause unknown) |
| onpromotion | bool | Whether the item was on promotion that day at that store | Official | False 96,028,767, True 7,810,622, empty 21,657,651 (17.3%; Official says ~16%). All empty values fall between 2013-01-01 and 2014-03-31, so promotions were not recorded before 2014-04-01. Empty means unknown, not "no promotion" |