import os
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

# Open-Meteo Geocoding API (free, no API key)
# Docs: https://open-meteo.com/en/docs/geocoding-api
url = "https://geocoding-api.open-meteo.com/v1/search"

# Kinds of place we accept as a real town.
# Codes are GeoNames feature codes (Open-Meteo docs: feature_code follows GeoNames).
# Definitions: https://www.geonames.org/EC/statistics.html
# PPL = populated place, PPLA to PPLA4 = seat of an administrative area, PPLC = capital
# Rejected after seeing them in test searches: PPLX (neighbourhood), AIRF (airfield), AIRP (airport), MT (mountain)
good_types = ["PPL", "PPLA", "PPLA2", "PPLA3", "PPLA4", "PPLC"]

# Dataset name -> official name to search.
# The dataset uses short everyday names; GeoNames uses official names.
# Basis (test searches, 22 Nov 2026):
#   "Libertad" did not return the real town; "La Libertad" did (Guayas, -2.233, -80.910)
#   "Playas" matched an inland village (-1.65, -80.02, next to Daule); the coastal town is
#   "General Villamil" (Guayas, -2.632, -80.388), with a "Playas" airfield beside it
#   "Santo Domingo" failed the name check; the provincial capital is
#   "Santo Domingo de los Colorados" (PPLA, -0.254, -79.176)
search_names = {
    "Libertad": "La Libertad",
    "Playas": "General Villamil",
    "Santo Domingo": "Santo Domingo de los Colorados",
}


def clean(text):
    # Make two names comparable: lowercase, remove accents, remove the word "province"
    # (basis: API returns "Tungurahua Province" and "Los Ríos"; stores.csv has "Tungurahua" and "Los Rios")
    text = text.lower()
    replacements = {"á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u", "ñ": "n"}
    for accented, plain in replacements.items():
        text = text.replace(accented, plain)
    text = text.replace(" province", "")
    return text


# Get each city and its province (expect 22, basis: Day 1 profiling)
cities = pd.read_sql("SELECT DISTINCT city, state FROM raw.stores ORDER BY city", engine)
print(len(cities), "cities")

# One dictionary per matched city, saved to the database after the loop
rows = []

for city, state in zip(cities["city"], cities["state"]):
    search_name = search_names.get(city, city)

    # countryCode filters results to Ecuador (ISO-3166-1 alpha-2 code, per the API docs)
    # count 20 instead of the default 10 (basis: the real La Libertad was cut off at 10)
    params = {"name": search_name, "countryCode": "EC", "count": 20}
    response = requests.get(url, params=params)

    if response.status_code != 200:
        print(city, "| ERROR", response.status_code)
        continue

    # .get() because the docs do not say what a search with no matches returns,
    # and empty fields like admin1 are left out of the response
    results = response.json().get("results", [])

    # Keep a result only if all three checks pass
    matches = []
    for place in results:
        same_name = clean(place["name"]) == clean(search_name)
        same_state = clean(place.get("admin1", "")) == clean(state)
        real_town = place["feature_code"] in good_types

        if same_name and same_state and real_town:
            matches.append(place)

    # Exactly one match is what we want; anything else gets checked by hand
    if len(matches) == 0:
        print(city, "| NO MATCH")
    elif len(matches) > 1:
        print(city, "| MORE THAN ONE MATCH:", len(matches))
    else:
        place = matches[0]
        print(city, "|", place["name"], "|", place["admin1"], "|", place["feature_code"], "|", place["latitude"], place["longitude"])
        rows.append({
            "city": city,
            "state": state,
            "geonames_name": place["name"],
            "feature_code": place["feature_code"],
            "latitude": place["latitude"],
            "longitude": place["longitude"],
        })

# Save only if every city got exactly one match (basis: no partial table in raw)
# city and state keep the dataset's own names, so weather can be joined to stores later
if len(rows) == len(cities):
    coordinates = pd.DataFrame(rows)
    coordinates.to_sql("city_coordinates", engine, schema="raw", if_exists="replace", index=False)
    print("Saved", len(coordinates), "rows to raw.city_coordinates")
else:
    print("Not saved:", len(rows), "of", len(cities), "cities matched")