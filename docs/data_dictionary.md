# Shelfcast data dictionary

Source labels:
- Official: Kaggle competition data page (favorita-grocery-sales-forecasting)
- Observed: our own profiling (notebooks/01_profiling.ipynb) and checks (sql/raw_checks.sql, sql/weather_checks.sql)
- Unknown: not documented anywhere, do not assume meaning
- Open-Meteo: Open-Meteo API documentation (used for the two tables we built ourselves: city_coordinates and weather_daily)
- Built: created by our dbt models (`shelfcast_dbt/models/`); the notes say which rule made the column

The raw tables are described first. The warehouse tables that everything downstream reads are under [Warehouse (dbt marts)](#warehouse-dbt-marts) at the end.

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
## city_coordinates (built by scripts/geocode_cities.py)
One row per store city. Key: city. 22 rows, no nulls. Built 2026-11-22 from the Open-Meteo Geocoding API, which returns GeoNames places.
How each city was matched: search the city name in Ecuador, then keep a result only if (1) the name matches, (2) the province matches stores.state, and (3) the place type is a real town (table below). Saved only when all 22 cities had exactly one match. All 22 coordinates were then checked by eye.

| column | dtype | meaning | source | notes |
|---|---|---|---|---|
| city | str | City name, exactly as in stores.csv | stores.csv | Join key to stores.city |
| state | str | Province, exactly as in stores.csv | stores.csv | |
| geonames_name | str | Official place name in GeoNames | Open-Meteo | Same as city for 19 cities. Differs for 3: Libertad → La Libertad, Playas → General Villamil, Santo Domingo → Santo Domingo de los Colorados (see DI-21) |
| feature_code | str | GeoNames place type | Open-Meteo (field), GeoNames (definitions) | PPLA 13, PPLA2 5, PPL 3 (La Libertad, General Villamil, Salinas), PPLC 1 (Quito) |
| latitude | float | Latitude of the town (WGS84) | Open-Meteo | |
| longitude | float | Longitude of the town (WGS84) | Open-Meteo | Checked by eye (Observed): coast towns −80.4 to −80.95, Andes cities about −78.5 to −79.2, Puyo (edge of the Amazon) −78.0 |

GeoNames feature codes we met, and whether a result with that code was accepted:

| code | meaning | accepted? | where we saw it |
|---|---|---|---|
| PPL | populated place (city, town or village) | Yes | La Libertad, General Villamil, Salinas |
| PPLA | seat of a first-order administrative division (provincial capital) | Yes | e.g. Ambato, Cuenca, Guayaquil |
| PPLA2 | seat of a second-order administrative division (canton capital) | Yes | e.g. Cayambe, Daule, Manta |
| PPLA3, PPLA4 | seat of a third- / fourth-order division | Yes | none in the final 22 |
| PPLC | capital of a country | Yes | Quito |
| PPLX | section of a populated place (a neighbourhood) | No | a "Libertad" inside Guayaquil |
| AIRF | airfield | No | "Playas", "Libertad" |
| AIRP | airport | No | "Ambato / Chachoan" |
| MT | mountain | No | "Ambato Loma" |

Sources: Open-Meteo Geocoding API docs (https://open-meteo.com/en/docs/geocoding-api: `feature_code` follows GeoNames), GeoNames feature codes used in Ecuador (https://www.geonames.org/EC/statistics.html).


## weather_daily (built by scripts/load_weather.py)
One row per city per day. Key: city + time. 37,136 rows (22 cities × 1,688 days), no nulls (checked).
Range: 2013-01-01 to 2017-08-15, the same as the sales data.
Built 2026-11-22 from the Open-Meteo Historical Weather API with `models=era5` and `timezone=America/Guayaquil`.

| column | dtype | meaning | source | notes |
|---|---|---|---|---|
| city | str | City, links to city_coordinates.city and stores.city | (ours) | 22 cities |
| time | date | Day, in Ecuador's local time | Open-Meteo | One weather day = one local calendar day, the same as a sales day |
| temperature_2m_max | float | Highest air temperature of the day, 2 m above ground, °C | Open-Meteo | City averages from 18.2 (Quito) to 30.8 (Daule) (Observed). Lowland and coastal cities 26.5–30.8, Andes cities 18.2–22.4 |
| temperature_2m_min | float | Lowest air temperature of the day, 2 m above ground, °C | Open-Meteo | City averages from about 10 (Andes) to 23.7 (Esmeraldas) (Observed). Never above the max (checked) |
| precipitation_sum | float | Total precipitation of the day (rain + snow), mm | Open-Meteo | Never negative (checked). Model values, not rain gauges: totals look too high in some cities (see DI-22). Use for "rainier than usual for this city", not as true amounts |

What the values are: ERA5 is a reanalysis, a weather model run over the past and corrected with observations. Each value belongs to a grid square of about 25 km (0.25°), not to a weather station. The API answers for the square nearest the city (e.g. Quito: requested −0.230, −78.525, answered −0.25, −78.5 at 2,858 m) and adjusts temperature for the city's elevation. Neighbouring towns can share a square: Salinas and La Libertad have identical precipitation (DI-23).
Column names are kept as the API returns them in raw; they are renamed in dbt staging.

Sources: Open-Meteo Historical Weather API docs (https://open-meteo.com/en/docs/historical-weather-api). Weather data by [Open-Meteo.com](https://open-meteo.com/) (CC BY 4.0), based on ERA5 from the Copernicus Climate Change Service.

## Warehouse (dbt marts)
Built by dbt in schema `analytics_marts` (PostgreSQL). Raw tables → staging views (`analytics_staging`, renames and type fixes) → intermediate (`analytics_intermediate`) → these marts. Week 2 and the API read only these tables.
Design: several fact tables at different grains sharing the same dimensions (`dim_date`, `dim_store`).

```
                      dim_item
                         │
dim_store ────────── fct_sales ────────── dim_date
   │  │                                      │
   │  └── fct_transactions              fct_oil_daily
   ├───── fct_weather_daily (via city)
   └───── dim_place_holidays (via city / state)
```

Rule for every mart: each table has a primary-key test, and every fact key has a relationships test to its dimension. Marts record what happened; forecast-specific cleaning (zero-filling, negatives, outliers, training window) happens later in the features layer.

### int_holidays_squashed (intermediate, view)
One row per date per place. Key: date + locale + locale_name (tested). 331 rows: National 160, Regional 24, Local 147.
Built from holidays_events: the 12 `transferred = True` rows are removed (DI-02), then rows are grouped by date and place so the 7 duplicate pairs become one row each (DI-01). Feeds `dim_date` (National rows) and `dim_place_holidays` (Regional and Local rows).

| column | dtype | meaning | source | notes |
|---|---|---|---|---|
| date, locale, locale_name | | As in holidays_events | Official | |
| is_holiday | bool | A Holiday or a Transfer (the day a moved holiday was really celebrated) | Built | DI-02 |
| is_additional | bool | Extra day around a holiday (e.g. Christmas Eve) | Built | |
| is_bridge | bool | Extra day off for a long weekend | Built | DI-03 |
| is_work_day | bool | Saturday worked to pay back a bridge | Built | DI-03 |
| is_event | bool | Event (earthquake days, Mother's Day, sports, shopping days) | Built | Mother's Day is an Event, not a Holiday |

### dim_store
One row per store. Key: store_nbr (tested). 54 rows.

| column | dtype | meaning | source | notes |
|---|---|---|---|---|
| store_nbr | int | Store ID | Official | |
| city, state | str | City and province | Official | |
| store_type | str | Type A–E | Unknown | Renamed from `type` |
| store_cluster | int | Favorita's store grouping | Official (meaning), Unknown (method) | Renamed from `cluster` so it can't be confused with our own K-means clusters |
| latitude, longitude | float | City coordinates | Open-Meteo | From city_coordinates, joined on city. Not null for every store (tested) |

### dim_item
One row per catalogue item. Key: item_nbr (tested). 4,100 rows, including the 64 items that were never sold (DI-20).

| column | dtype | meaning | source | notes |
|---|---|---|---|---|
| item_nbr | int | Item ID | Official | |
| family | str | Product category | Observed | Tidied to lowercase with underscores, e.g. `LIQUOR,WINE,BEER` → `liquor_wine_beer`, `BREAD/BAKERY` → `bread_bakery` (DI-19). 33 families |
| item_class | int | Sub-category code | Observed | Renamed from `class` |
| is_perishable | bool | Perishable item | Official | From `perishable = 1` |

### dim_date
One row per calendar day, 2013-01-01 to 2017-08-31. Key: date (tested). 1,704 rows.
Holds only things known in advance (calendar, paydays, national holidays). Ends 16 days after the sales data so a 14-day forecast from the last day has calendar information.

| column | dtype | meaning | source | notes |
|---|---|---|---|---|
| date | date | Calendar day | Built | |
| year, month, day_of_month | int | Parts of the date | Built | |
| day_of_week | int | 1 = Monday … 7 = Sunday (ISO) | Built | Values 1–7 only (tested) |
| is_weekend | bool | Saturday or Sunday | Built | |
| is_payday | bool | 15th or last day of the month | Official (public-sector wages, Kaggle notes) | 112 paydays |
| is_national_holiday | bool | National Holiday or Transfer day | Built | From int_holidays_squashed. False on the official dates of the 7 transferred national holidays (checked) |
| is_national_additional, is_national_bridge, is_national_work_day, is_national_event | bool | National Additional / Bridge / Work Day / Event | Built | False on days with no national row |

### dim_place_holidays
Regional and local holidays. One row per date per place. Key: date + locale + locale_name (tested). 171 rows (Regional 24, Local 147).
Join: Regional rows on a store's state, Local rows on a store's city. Every locale_name matches a store city or state (tested).
Columns: date, locale, locale_name and the five flags of int_holidays_squashed.

### fct_sales
One row per store × item × day with sales. Key: date + store_nbr + item_nbr (tested). 125,497,040 rows.
Keys and measures only; descriptions come from the dimensions. Indexed on (store_nbr, item_nbr, date) for fast lookups of one store-item's history.

| column | dtype | meaning | source | notes |
|---|---|---|---|---|
| date, store_nbr, item_nbr | | Keys | Official | Every store, item and date exists in its dimension (tested) |
| unit_sales | float | Units (or kg) sold | Official | Kept as recorded: returns stay negative (DI-14), extremes kept (DI-15) |
| onpromotion | bool | On promotion | Official | NULL before 2014-04-01 = not recorded (DI-13) |

Zero-sales days still have no row (DI-11). Raw `id` is not carried over.

### fct_transactions
One row per store per day. Key: date + store_nbr (tested). 83,488 rows.
Columns: date, store_nbr, transaction_count (renamed from `transactions`, never null). A missing row means "not recorded", never zero (DI-09, DI-10).

### fct_oil_daily
One row per calendar day. Key: date (tested). 1,704 rows.
Columns: date, oil_price (WTI, US dollars per barrel). Weekends and days with a null price get the last known price (DI-06, DI-07): e.g. Saturday and Sunday 2013-01-05/06 carry Friday's 93.12. Only 2013-01-01 is NULL: oil.csv starts with an empty price and there is no earlier price to carry forward (tested). Kept apart from dim_date because the price is measured each day, not known in advance; features may only use prices from before the forecast date (DI-08).

### fct_weather_daily
One row per city per day. Key: city + date (tested). 37,136 rows.
Columns: city, date, temp_max, temp_min, precipitation (renamed from the API names). Every city exists in dim_store and every date in dim_date (tested). Rain amounts are biased in some cities (DI-22).