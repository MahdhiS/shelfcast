-- Reference only: these checks now run as dbt tests (shelfcast_dbt/tests and sources.yml).

-- Expect 22 rows (basis: Day 1 profiling found 22 cities)
SELECT DISTINCT city, state
FROM raw.stores
ORDER BY city;

-- Expect 22 rows, one per city (basis: 22 cities in raw.stores)
SELECT COUNT(*) AS n_rows, COUNT(DISTINCT city) AS n_cities
FROM raw.city_coordinates;

-- Expect 37,136 rows, 22 cities, 2013-01-01 to 2017-08-15
-- (basis: 22 cities x 1,688 days; same period as train)
SELECT COUNT(*) AS n_rows,
       COUNT(DISTINCT city) AS n_cities,
       MIN(time) AS first_day,
       MAX(time) AS last_day
FROM raw.weather_daily;

-- Expect 0 rows: no city with a missing or repeated day (basis: 1,688 days each)
SELECT city, COUNT(*) AS n_days
FROM raw.weather_daily
GROUP BY city
HAVING COUNT(*) <> 1688;

-- Expect 0 rows: min temperature can't be above max, and rain can't be negative
-- (basis: physical sense; catches values in the wrong column)
SELECT *
FROM raw.weather_daily
WHERE temperature_2m_min > temperature_2m_max
   OR precipitation_sum < 0;


-- By-eye check: coastal cities should be hot, Andes cities cool, Puyo (Amazon edge) wet
-- (basis: Ecuador's geography; catches weather attached to the wrong city)
SELECT city,
       ROUND(AVG(temperature_2m_max)::numeric, 1) AS avg_max_temp,
       ROUND(AVG(temperature_2m_min)::numeric, 1) AS avg_min_temp,
       ROUND((SUM(precipitation_sum) / 4.6)::numeric, 0) AS rain_mm_per_year
FROM raw.weather_daily
GROUP BY city
ORDER BY avg_max_temp DESC;




