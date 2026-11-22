import os
import time
from urllib.parse import quote_plus

import pandas as pd
import requests
from dotenv import load_dotenv
from sqlalchemy import create_engine

# Connect to the database (same as load_raw.py)
# quote_plus encodes the "@" in the password so the URL stays valid
load_dotenv()
user = os.getenv("DB_USER")
password = quote_plus(os.getenv("DB_PASSWORD"))
host = os.getenv("DB_HOST")
port = os.getenv("DB_PORT")
db_name = os.getenv("DB_NAME")
engine = create_engine(f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{db_name}")

# Open-Meteo Historical Weather API (free, no API key)
# Docs: https://open-meteo.com/en/docs/historical-weather-api
url = "https://archive-api.open-meteo.com/v1/archive"

# Same period as the sales data (basis: train.csv runs 2013-01-01 to 2017-08-15)
start_date = "2013-01-01"
end_date = "2017-08-15"

# Number of days we expect per city: every day in the period (1,688)
expected_days = len(pd.date_range(start_date, end_date))

# Daily variables (decided 22 Nov 2026): the ones most likely to change shopping
#   temperature_2m_max / temperature_2m_min = daily max / min air temperature at 2 m, in °C
#   precipitation_sum = total daily precipitation (rain + snow), in mm
daily_variables = "temperature_2m_max,temperature_2m_min,precipitation_sum"

# Timezone: the docs say daily variables need one.
# Ecuador's timezone makes one weather day = one local calendar day, the same as a sales day.
timezone = "America/Guayaquil"

# Data source: ERA5 (global reanalysis, ~25 km grid, 1940 to present).
# One source for every variable and every year, so the data stays consistent.
# Basis (Quito test, 22 Nov 2026):
#   era5_land returned 1,688 missing precipitation values (temperature was complete)
#   era5 returned all three variables with 0 missing
#   best_match (the default) mixes sources: its temperatures matched era5_land, its rain matched era5
model = "era5"

# Get the 22 cities and their coordinates (made by scripts/geocode_cities.py)
cities = pd.read_sql("SELECT city, latitude, longitude FROM raw.city_coordinates ORDER BY city", engine)
print(len(cities), "cities,", expected_days, "days expected per city")

# One weather table per city that passed the checks
city_tables = []

for city, latitude, longitude in zip(cities["city"], cities["latitude"], cities["longitude"]):
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "start_date": start_date,
        "end_date": end_date,
        "daily": daily_variables,
        "timezone": timezone,
        "models": model,
    }
    response = requests.get(url, params=params)

    # 429 = Too Many Requests: we hit the free per-minute limit, so wait a minute and try again
    # (basis: first full run got 429 after 17 cities; a test request right after returned 200,
    # so the limit resets quickly. Free limits: 600 calls/minute, 5,000/hour, 10,000/day,
    # and a long date range counts as several calls. Source: https://open-meteo.com/en/terms)
    tries = 1
    while response.status_code == 429 and tries < 4:
        print(city, "| rate limit hit, waiting 60 seconds (try", tries, "of 3)")
        time.sleep(60)
        response = requests.get(url, params=params)
        tries = tries + 1

    if response.status_code != 200:
        print(city, "| ERROR", response.status_code)
        continue

    # The response holds one list per column, all the same length:
    # time, temperature_2m_max, temperature_2m_min, precipitation_sum
    daily = response.json()["daily"]

    # Each key becomes a column, each list position becomes a row (one row per day)
    weather = pd.DataFrame(daily)

    # Real dates instead of text, same as load_raw.py, so Postgres stores a date type
    # (needed later to join weather to sales on the date)
    weather["time"] = pd.to_datetime(weather["time"]).dt.date

    # City column first, so we know whose weather each row is after stacking
    weather.insert(0, "city", city)

    # Check 1: every day in the period is there
    n_days = len(weather)
    # Check 2: no missing values in any column (basis: era5_land had a fully empty precipitation column)
    n_missing = int(weather.isna().sum().sum())

    if n_days != expected_days or n_missing > 0:
        print(city, "| FAILED:", n_days, "days,", n_missing, "missing values")
        continue

    print(city, "| OK:", n_days, "days, 0 missing")
    city_tables.append(weather)

    # Pause between requests to stay under the per-minute limit
    # (basis: with 1-second pauses we hit the limit after 17 cities; 10 seconds = 6 requests a minute)
    time.sleep(10)

# Save only if every city passed (basis: no partial table in raw, same rule as geocode_cities.py)
if len(city_tables) == len(cities):
    weather_daily = pd.concat(city_tables, ignore_index=True)
    weather_daily.to_sql("weather_daily", engine, schema="raw", if_exists="replace", index=False)
    print("Saved", len(weather_daily), "rows to raw.weather_daily")
else:
    print("Not saved:", len(city_tables), "of", len(cities), "cities passed")