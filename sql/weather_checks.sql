-- Expect 22 rows (basis: profiling found 22 cities)
SELECT DISTINCT city, state
FROM raw.stores
ORDER BY city;

-- Expect 22 rows, one per city (basis: 22 cities in raw.stores)
SELECT COUNT(*) AS n_rows, COUNT(DISTINCT city) AS n_cities
FROM raw.city_coordinates;