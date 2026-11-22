# Shelfcast

**Grocery demand forecasting and replenishment system** built on 125 million rows of real supermarket sales.

Shelfcast predicts how many units of each product each store will sell over the next 14 days, recommends order quantities, explains unusual demand, and tracks forecast accuracy over time.

> **Status:** in progress (week 1 of 3: data engineering). Results will appear here as they are produced.

---

## Why

Supermarkets lose money in both directions: too little stock means empty shelves and lost sales, too much means waste, especially for perishable food. Shelfcast turns daily sales history, holidays, promotions, oil prices and weather into forecasts a store can order from.

## Data

| Source | What | Size |
|---|---|---|
| [Corporación Favorita (Kaggle)](https://www.kaggle.com/competitions/favorita-grocery-sales-forecasting/data) | Daily item sales for 54 stores in Ecuador, 2013-01-01 to 2017-08-15, plus stores, items, transactions, holidays and oil prices | 125M sales rows |
| [Open-Meteo](https://open-meteo.com/) historical weather (ERA5) | Daily max/min temperature and precipitation for the 22 store cities, 2013-01-01 to 2017-08-15 | 37,136 rows |

The raw data is not included in this repo (size and licence). See [Getting started](#getting-started) to download it.

Weather data by [Open-Meteo.com](https://open-meteo.com/) ([CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)), based on ERA5 from the Copernicus Climate Change Service. City coordinates from the Open-Meteo Geocoding API (GeoNames).

## Architecture

```mermaid
flowchart TD
    A[Kaggle CSVs + Open-Meteo weather] --> B[Python ingest]
    B --> C[(PostgreSQL: raw)]
    C --> D[dbt: staging → marts → features + tests]
    D --> E[Models: K-means clusters · LightGBM forecast · spike classifier + SHAP]
    E --> F[MLflow experiment tracking]
    F --> G[FastAPI service + dashboard]
    D -.-> H[Databricks version: Delta Lake, MLflow, Jobs]
```

| Layer | Tools |
|---|---|
| Ingestion | Python, pandas, psycopg2 (PostgreSQL `COPY`), requests (Open-Meteo APIs) |
| Warehouse | PostgreSQL, dbt Core (with data tests and docs) |
| Modelling | scikit-learn (K-means), LightGBM, SHAP |
| Tracking | MLflow |
| Serving | FastAPI, Jinja2, Chart.js |
| Production | Docker, GitHub Actions, Databricks (Delta Lake, Jobs) |

## Results

*Coming in weeks 2 and 3:* forecast accuracy (WAPE and MAE) against a seasonal-naive baseline, per-family accuracy, spike-classifier precision and recall, and a link to the live demo.

## Progress

- [x] Project setup (uv, Python 3.12)
- [x] Profiling of all six raw files ([notebook](notebooks/01_profiling.ipynb), [data dictionary](docs/data_dictionary.md))
- [x] Raw data loaded into PostgreSQL (125,497,040 sales rows, all counts checked against profiling)
- [x] City coordinates and historical weather for 22 cities
- [ ] dbt warehouse with tests and docs
- [ ] Exploratory analysis
- [ ] Baseline and LightGBM forecast, tracked in MLflow
- [ ] Product clustering, spike classifier with SHAP, order quantities
- [ ] FastAPI service and monitoring dashboard
- [ ] Databricks version, Docker, CI, live demo *(raw data already loaded into Databricks and checked against PostgreSQL)*

## Repo layout

```
shelfcast/
├── data/raw/            # Kaggle CSVs (not in git)
├── docs/
│   ├── data_dictionary.md   # what every column means, and where that comes from
│   └── data_issues.md       # data-quality problems and how each is handled
├── notebooks/
│   └── 01_profiling.ipynb   # first look at every raw file
├── scripts/             # load the raw data and build the weather tables
├── sql/                 # checks run after each load (temporary, until they become dbt tests)
├── src/shelfcast/       # reusable Python code (ingestion, later more)
├── pyproject.toml
└── uv.lock
```

## Getting started

**Prerequisites:** Python 3.12, [uv](https://docs.astral.sh/uv/), PostgreSQL.

1. **Install dependencies**
   ```bash
   uv sync
   ```
2. **Download the data.** On the [Kaggle data page](https://www.kaggle.com/competitions/favorita-grocery-sales-forecasting/data), accept the competition rules, download the files and extract these CSVs into `data/raw/`:
   `train.csv`, `items.csv`, `stores.csv`, `transactions.csv`, `oil.csv`, `holidays_events.csv`
3. **Database.** Create a PostgreSQL database called `shelfcast` with a schema called `raw`. Copy `.env.example` to `.env` and fill in your connection details (`.env` is never committed).
4. **Load the data** (run from the repo root, in this order):
   ```bash
   uv run python scripts/test_connection.py   # checks the database connection
   uv run python scripts/load_raw.py          # stores, items, oil, holidays_events, transactions
   uv run python scripts/load_train.py        # train (125M rows, uses PostgreSQL COPY)
   uv run python scripts/geocode_cities.py    # coordinates for the 22 store cities
   uv run python scripts/load_weather.py      # daily weather for those cities (takes about 4 minutes)
   ```
   The checks in `sql/raw_checks.sql` and `sql/weather_checks.sql` list the expected results.

## Documentation

- [Data dictionary](docs/data_dictionary.md): every column, labelled Official (Kaggle), Observed (our checks) or Unknown
- [Data issues](docs/data_issues.md): every data problem found and how it is handled

## Author

Mahdhi Shafraz, Data Science undergraduate, SLIIT