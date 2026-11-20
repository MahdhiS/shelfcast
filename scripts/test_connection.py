import os
from urllib.parse import quote_plus

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine

# read the values from .env
load_dotenv()

user = os.getenv('DB_USER')
password = os.getenv('DB_PASSWORD')
host = os.getenv('DB_HOST')
port = os.getenv('DB_PORT')
db_name = os.getenv('DB_NAME')

# encode the password so the @ doesn't break the URL
safe_password = quote_plus(password)

# build the connection URL and the engine
url = f'postgresql+psycopg2://{user}:{safe_password}@{host}:{port}/{db_name}'
engine = create_engine(url)

# test query
result = pd.read_sql('SELECT 1 AS test', engine)
print('connection test: ')
print(result)