-- Checks that the raw load (Day 2) matches the Day 1 profiling.
-- Run in pgAdmin while connected to the shelfcast database.
-- Highlight one query and press F5. Every expected value comes from notebooks/01_profiling.ipynb.
-- These become dbt tests on Day 4.


-- Row counts: nothing lost or duplicated during loading
SELECT COUNT(*) FROM raw.stores;             -- expected 54
SELECT COUNT(*) FROM raw.items;              -- expected 4100
SELECT COUNT(*) FROM raw.oil;                -- expected 1218
SELECT COUNT(*) FROM raw.holidays_events;    -- expected 350
SELECT COUNT(*) FROM raw.transactions;       -- expected 83488
SELECT COUNT(*) FROM raw.train;              -- expected 125497040


-- oil: empty prices became real NULLs (expected 43)
SELECT COUNT(*) FROM raw.oil WHERE dcoilwtico IS NULL;

-- transactions: dates stored as dates (expected 2013-01-01 to 2017-08-15)
SELECT MIN(date), MAX(date) FROM raw.transactions;

-- holidays_events: True/False became a real boolean (expected 12)
SELECT COUNT(*) FROM raw.holidays_events WHERE transferred = true;

-- stores: text arrived intact (expected 22)
SELECT COUNT(DISTINCT city) FROM raw.stores;


-- train: dates (expected 2013-01-01 to 2017-08-15)
SELECT MIN(date), MAX(date) FROM raw.train;

-- train: empty promotions stayed NULL, not False
-- expected: false 96028767, true 7810622, NULL 21657651
SELECT onpromotion, COUNT(*) FROM raw.train GROUP BY onpromotion;

-- train: size on disk (measured 6246 MB on 2026-11-20)
SELECT pg_size_pretty(pg_total_relation_size('raw.train'));