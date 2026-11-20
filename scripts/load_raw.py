import os
from urllib.parse import quote_plus

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine

# connect to the database (same code as test_connection.py)
load_dotenv()

user = os.getenv('DB_USER')
password = os.getenv('DB_PASSWORD')
host = os.getenv('DB_HOST')
port = os.getenv('DB_PORT')
db_name = os.getenv('DB_NAME')

safe_password = quote_plus(password)
url = f'postgresql+psycopg2://{user}:{safe_password}@{host}:{port}/{db_name}'
engine = create_engine(url)

# small tables and the row counts we found on Day 1 (profiling notebook)
expected_rows = {
    'stores': 54,
    'items': 4100,
    'oil': 1218,
    'holidays_events': 350,
    'transactions': 83488,
}

for table in expected_rows:
    print('loading: ', table)

    df = pd.read_csv(f'data/raw/{table}.csv')

    # store dates as real dates, not text
    if 'date' in df.columns:
        df['date'] = pd.to_datetime(df['date']).dt.date

    df.to_sql(table, engine, schema='raw', if_exists='replace', index=False)

    # check: did every row arrive?
    count_query = f'SELECT COUNT(*) AS row_count FROM raw.{table}'
    loaded = pd.read_sql(count_query, engine)['row_count'][0]

    print('rows in database: ', loaded)
    print('rows expected: ', expected_rows[table])
    print('match: ', loaded == expected_rows[table])
    print()