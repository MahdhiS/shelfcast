import os

import psycopg2
from dotenv import load_dotenv

load_dotenv()

# psycopg2 takes the values directly, so no URL and no password encoding
conn = psycopg2.connect(
    user=os.getenv('DB_USER'),
    password=os.getenv('DB_PASSWORD'),
    host=os.getenv('DB_HOST'),
    port=os.getenv('DB_PORT'),
    dbname=os.getenv('DB_NAME'),
)
cursor = conn.cursor()

# step 1: create an empty table with the column types we chose on Day 1
create_table = '''
DROP TABLE IF EXISTS raw.train;
CREATE TABLE raw.train (
    id          integer,
    date        date,
    store_nbr   smallint,
    item_nbr    integer,
    unit_sales  real,
    onpromotion boolean
);
'''
cursor.execute(create_table)
print('table created')

# step 2: stream the CSV into the table with COPY
copy_command = 'COPY raw.train FROM STDIN WITH (FORMAT csv, HEADER true)'

print('copying train.csv (this can take a while)...')
with open('data/raw/train.csv', 'r', encoding='utf-8') as file:
    cursor.copy_expert(copy_command, file)

# step 3: save everything (nothing is saved until commit)
conn.commit()
print('copy finished')
print()

# step 4: check the row count against Day 1
cursor.execute('SELECT COUNT(*) FROM raw.train')
loaded = cursor.fetchone()[0]
expected = 125497040

print('rows in database: ', loaded)
print('rows expected: ', expected)
print('match: ', loaded == expected)

cursor.close()
conn.close()