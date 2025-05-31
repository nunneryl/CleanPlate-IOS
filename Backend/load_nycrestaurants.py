import os
import psycopg2
import requests
import logging
from dateutil.parser import parse as date_parse

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DB_NAME = os.environ.get("DB_NAME", "nyc_restaurant_db")
DB_USER = os.environ.get("DB_USER", "postgres")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "1qaz2wsx!QAZ@WSX")
DB_HOST = os.environ.get("DB_HOST", "localhost")

try:
    conn = psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST
    )
    logger.info("Connected to database")
except Exception as e:
    logger.error("Database connection failed: %s", e)
    raise e

def convert_date(date_str):
    if not date_str or date_str == "N/A":
        return None
    try:
        dt = date_parse(date_str)
        return dt.date()
    except Exception as e:
        logger.error("Error parsing date %s: %s", date_str, e)
        return None

def convert_float(value):
    if not value or value == "N/A":
        return None
    try:
        return float(value)
    except ValueError as e:
        logger.error("Error converting value to float: %s", e)
        return None

limit = 50000
offset = 0
total_rows_fetched = 0

while True:
    url = f"https://data.cityofnewyork.us/resource/43nn-pn8j.json?$limit={limit}&$offset={offset}"
    try:
        response = requests.get(url)
    except Exception as e:
        logger.error("Error fetching data: %s", e)
        break

    try:
        data = response.json()
    except Exception as e:
        logger.error("Error parsing JSON: %s", e)
        break

    if not data:
        logger.info("All data fetched. Total rows inserted: %s", total_rows_fetched)
        break

    for item in data:
        try:
            # Truncate and replace missing values with defaults
            camis = item.get("camis", "N/A")
            dba = item.get("dba", "N/A")[:255]
            building = item.get("building", "N/A")[:50]
            street = item.get("street", "N/A")[:255]
            boro = item.get("boro", "N/A")[:50]
            zipcode = item.get("zipcode", "N/A")[:20]
            phone = item.get("phone", "N/A")[:20]
            cuisine_description = item.get("cuisine_description", "N/A")[:255]
            grade = item.get("grade", "N/A")[:10]
            grade_date = convert_date(item.get("grade_date", None))
            inspection_date = convert_date(item.get("inspection_date", None))
            violation_code = item.get("violation_code", "N/A")[:50]
            violation_description = item.get("violation_description", "N/A")
            inspection_type = item.get("inspection_type", "N/A")[:255]
            critical_flag = item.get("critical_flag", "N/A")[:50]
            record_date = convert_date(item.get("record_date", None))
            latitude = convert_float(item.get("latitude", None))
            longitude = convert_float(item.get("longitude", None))
            community_board = item.get("community_board", "N/A")[:10]
            council_district = item.get("council_district", "N/A")[:10]
            census_tract = item.get("census_tract", "N/A")[:10]
            bin_val = item.get("bin", "N/A")[:10]  # Avoid using built-in 'bin'
            bbl = item.get("bbl", "N/A")[:10]
            nta = item.get("nta", "N/A")[:10]

            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO restaurants (
                        camis, dba, boro, building, street, zipcode, phone, inspection_date,
                        critical_flag, record_date, latitude, longitude, community_board,
                        council_district, census_tract, bin, bbl, nta, cuisine_description,
                        grade, grade_date, inspection_type
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (camis, inspection_date) DO UPDATE SET
                        dba = EXCLUDED.dba,
                        boro = EXCLUDED.boro,
                        building = EXCLUDED.building,
                        street = EXCLUDED.street,
                        zipcode = EXCLUDED.zipcode,
                        phone = EXCLUDED.phone,
                        cuisine_description = EXCLUDED.cuisine_description,
                        grade = EXCLUDED.grade,
                        grade_date = EXCLUDED.grade_date,
                        inspection_type = EXCLUDED.inspection_type,
                        critical_flag = EXCLUDED.critical_flag,
                        record_date = EXCLUDED.record_date,
                        latitude = EXCLUDED.latitude,
                        longitude = EXCLUDED.longitude,
                        community_board = EXCLUDED.community_board,
                        council_district = EXCLUDED.council_district,
                        census_tract = EXCLUDED.census_tract,
                        bin = EXCLUDED.bin,
                        bbl = EXCLUDED.bbl,
                        nta = EXCLUDED.nta
                """, (
                    camis, dba, boro, building, street, zipcode, phone, inspection_date,
                    critical_flag, record_date, latitude, longitude, community_board,
                    council_district, census_tract, bin_val, bbl, nta, cuisine_description,
                    grade, grade_date, inspection_type
                ))
                cur.execute("""
                    INSERT INTO violations (
                        camis, inspection_date, violation_code, violation_description
                    ) VALUES (%s, %s, %s, %s)
                    ON CONFLICT DO NOTHING
                """, (
                    camis, inspection_date, violation_code, violation_description
                ))
        except psycopg2.Error as e:
            logger.error("Error inserting record: %s", e)
            conn.rollback()

    conn.commit()
    offset += limit
    total_rows_fetched += len(data)
    logger.info("Rows fetched: %s, Total rows so far: %s", len(data), total_rows_fetched)

conn.close()
