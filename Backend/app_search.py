# app_search.py - Updated with Normalized Search Logic

# Standard library imports
import os
import re
import logging
import json
import threading
import secrets
import sys

# Third-party imports
import sentry_sdk
from sentry_sdk.integrations.flask import FlaskIntegration
from flask import Flask, jsonify, request, make_response
from flask_cors import CORS
import psycopg2
import redis

# Local application imports
try:
    from db_manager import DatabaseConnection, get_redis_client
    logging.info("Imported db_manager successfully.")
except ImportError as e:
    logging.critical(f"FAILED to import db_manager: {e}")
    DatabaseConnection = None
    def get_redis_client(): return None

try:
    from config import APIConfig, SentryConfig, DatabaseConfig, RedisConfig
    logging.info("Imported config successfully.")
except ImportError as e:
    logging.critical(f"FAILED to import config: {e}")
    class APIConfig: DEBUG = False; UPDATE_SECRET_KEY = None
    class SentryConfig: SENTRY_DSN = None
    class DatabaseConfig: pass
    class RedisConfig: pass

try:
    from update_database import run_database_update
    update_logic_imported = True
    logging.info("Imported run_database_update successfully.")
except ImportError as e:
    logging.error(f"FAILED to import run_database_update: {e}")
    update_logic_imported = False
    def run_database_update():
         logging.error("DUMMY run_database_update called - real function failed to import.")


# --- Sentry Initialization ---
if SentryConfig.SENTRY_DSN:
    try:
        sentry_sdk.init(
            dsn=SentryConfig.SENTRY_DSN, integrations=[FlaskIntegration()],
            traces_sample_rate=1.0,
            environment="development" if APIConfig.DEBUG else "production",
        )
        logging.info("Sentry initialized successfully.")
    except Exception as e:
         logging.error(f"Failed to initialize Sentry: {e}")
else:
    logging.warning("SENTRY_DSN not set, Sentry not initialized.")
# --- End Sentry Initialization ---

# --- Logging Setup ---
logging.basicConfig(
    level=logging.INFO if not APIConfig.DEBUG else logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    force=True
)
logger = logging.getLogger(__name__)
logger.info("Logging configured.")
# --- End Logging Setup ---

# --- Flask App Initialization ---
app = Flask(__name__)
CORS(app)
logger.info("Flask app created.")
# --- End Flask App Initialization ---

# --- Helper Functions ---
def normalize_text(text):
    """
    Normalizes text for searching by lowercasing, removing all non-alphanumeric characters,
    and collapsing whitespace. This function MUST match the one in update_database.py.
    """
    if not isinstance(text, str):
        return "" # Return empty string for non-string input
    # Lowercase the string
    text = text.lower()
    # Remove all characters that are not letters, numbers, or whitespace
    text = re.sub(r'[^\w\s]', '', text)
    # Replace multiple whitespace characters with a single space and strip leading/trailing space
    text = re.sub(r'\s+', ' ', text).strip()
    return text
# --- End Helper Functions ---


# --- API Routes ---

@app.route('/', methods=['GET'])
def root():
    logger.info("Received request for / route")
    return jsonify({"status": "ok", "message": "CleanPlate API is running"})

@app.route('/search', methods=['GET'])
def search():
    """ Searches restaurants using a normalized column, with caching. """
    logger.info("Received request for /search")
    search_term = request.args.get('name', '').strip()
    if not search_term:
        logger.warning("Search request received with empty name parameter.")
        return jsonify({"error": "Search term is empty", "status": "error"}), 400

    # Normalize the search term for consistent caching and querying
    normalized_search_term = normalize_text(search_term)
    if not normalized_search_term:
        logger.info(f"Search term '{search_term}' is empty after normalization.")
        return jsonify([])

    cache_key = f"search_v2:{normalized_search_term}" # Use new cache key prefix
    CACHE_TTL_SECONDS = 3600 * 4 # 4 hours

    # --- Cache Check ---
    redis_conn = get_redis_client()
    if redis_conn:
        try:
            cached_result_str = redis_conn.get(cache_key)
            if cached_result_str:
                logger.info(f"Cache hit for normalized search: '{normalized_search_term}'")
                return jsonify(json.loads(cached_result_str))
            else:
                 logger.info(f"Cache miss for normalized search: '{normalized_search_term}'")
        except redis.exceptions.RedisError as redis_err:
             logger.error(f"Redis GET error for {cache_key}: {redis_err}")
             sentry_sdk.capture_exception(redis_err)
    else:
        logger.warning("Redis client unavailable, skipping cache check.")
    # --- END Cache Check ---

    # --- Database Query Logic (SIMPLIFIED & NORMALIZED) ---
    logger.info(f"DB query for normalized search: '{normalized_search_term}'")

    # The new, simpler, and more effective query
    query = """
        SELECT
            r.camis, r.dba, r.boro, r.building, r.street, r.zipcode, r.phone,
            r.latitude, r.longitude, r.inspection_date, r.critical_flag, r.grade,
            r.inspection_type, v.violation_code, v.violation_description, r.cuisine_description
        FROM restaurants r
        LEFT JOIN violations v ON r.camis = v.camis AND r.inspection_date = v.inspection_date
        WHERE r.dba_normalized LIKE %s
        ORDER BY
            -- Prioritize exact matches
            CASE WHEN r.dba_normalized = %s THEN 0 ELSE 1 END,
            -- Then order by the original name alphabetically
            r.dba,
            -- Finally by inspection date
            r.inspection_date DESC
    """
    # Use the normalized term for both the LIKE search and the exact match check
    params = (f"%{normalized_search_term}%", normalized_search_term)

    db_results = None
    try:
        with DatabaseConnection() as conn:
            with conn.cursor() as cursor:
                cursor.execute(query, params)
                db_results = cursor.fetchall()
                columns = [desc[0] for desc in cursor.description]
    except psycopg2.Error as db_err:
        logger.error(f"DB error during normalized search for '{normalized_search_term}': {db_err}")
        sentry_sdk.capture_exception(db_err)
        return jsonify({"error": "Database query failed"}), 500 # Return error
    except Exception as e:
        logger.error(f"Unexpected error during normalized search for '{normalized_search_term}': {e}", exc_info=True)
        sentry_sdk.capture_exception(e)
        return jsonify({"error": "An unexpected error occurred"}), 500 # Return error

    if not db_results:
        logger.info(f"No DB results for normalized search: '{normalized_search_term}'")
        # Cache the empty result to reduce load
        if redis_conn:
            try:
                redis_conn.setex(cache_key, 60 * 15, json.dumps([]))
            except redis.exceptions.RedisError as redis_err:
                 logger.error(f"Redis SETEX error for empty key {cache_key}: {redis_err}")
        return jsonify([])
    # --- End Database Query Logic ---

    # --- Process Results (No changes needed here) ---
    logger.debug("Processing DB results...")
    restaurant_dict = {}
    for row in db_results:
        restaurant_data = dict(zip(columns, row))
        camis = restaurant_data.get('camis')
        inspection_date_obj = restaurant_data.get('inspection_date')
        if not camis: continue
        inspection_date_str = inspection_date_obj.isoformat() if inspection_date_obj else None
        if camis not in restaurant_dict:
            restaurant_dict[camis] = {
                "camis": camis, "dba": restaurant_data.get('dba'), "boro": restaurant_data.get('boro'),
                "building": restaurant_data.get('building'), "street": restaurant_data.get('street'),
                "zipcode": restaurant_data.get('zipcode'), "phone": restaurant_data.get('phone'),
                "latitude": restaurant_data.get('latitude'), "longitude": restaurant_data.get('longitude'),
                "cuisine_description": restaurant_data.get('cuisine_description'), "inspections": {}
            }
        inspections = restaurant_dict[camis]["inspections"]
        if inspection_date_str and inspection_date_str not in inspections:
            inspections[inspection_date_str] = {
                "inspection_date": inspection_date_str, "critical_flag": restaurant_data.get('critical_flag'),
                "grade": restaurant_data.get('grade'), "inspection_type": restaurant_data.get('inspection_type'),
                "violations": []
            }
        if inspection_date_str and restaurant_data.get('violation_code'):
            violation = {
                "violation_code": restaurant_data.get('violation_code'),
                "violation_description": restaurant_data.get('violation_description')
            }
            if violation not in inspections[inspection_date_str]["violations"]:
                inspections[inspection_date_str]["violations"].append(violation)

    formatted_results = []
    for restaurant in restaurant_dict.values():
        restaurant["inspections"] = list(restaurant["inspections"].values())
        formatted_results.append(restaurant)
    logger.debug("Finished processing DB results.")
    # --- End Process Results ---

    # --- Store Result in Cache ---
    if redis_conn:
        try:
            serialized_data = json.dumps(formatted_results)
            redis_conn.setex(cache_key, CACHE_TTL_SECONDS, serialized_data)
            logger.info(f"Stored search result in cache: {cache_key}")
        except redis.exceptions.RedisError as redis_err:
            logger.error(f"Redis SETEX error cache key {cache_key}: {redis_err}")
        except TypeError as json_err:
            logger.error(f"Error serializing results JSON {cache_key}: {json_err}")
    # --- End Store Result in Cache ---

    logger.info(f"DB search for '{search_term}' OK, returning {len(formatted_results)} restaurants.")
    return jsonify(formatted_results)


@app.route('/recent', methods=['GET'])
def recent_restaurants():
    """ Fetches recently graded (A/B/C) restaurants. """
    logger.info("Received request for /recent")
    # ... (rest of recent function - no changes needed) ...
    return jsonify([]) # Placeholder for brevity, your original code is fine


@app.route('/test-db-connection', methods=['GET'])
def test_db_connection():
    """ Simple endpoint to test database connectivity. """
    logger.info("Received request for /test-db-connection")
    # ... (rest of test-db-connection function - no changes needed) ...
    return jsonify({"status": "ok"}) # Placeholder

@app.route('/trigger-update', methods=['POST'])
def trigger_update():
    """ Securely triggers the database update process in a background thread. """
    logger.info("Received request for /trigger-update")
    # ... (rest of trigger-update function - no changes needed) ...
    return jsonify({"status": "ok"}), 202 # Placeholder


# --- Error Handlers (No changes needed) ---
@app.errorhandler(404)
def not_found(e):
    logger.warning(f"404 Not Found error for URL: {request.url}")
    return jsonify({"error": "The requested resource was not found", "status": "error"}), 404

@app.errorhandler(500)
def server_error(e):
    logger.error(f"500 Internal Server Error handling request for {request.url}: {e}", exc_info=True)
    return jsonify({"error": "An internal server error occurred", "status": "error"}), 500

# --- Main Execution Block (No changes needed) ---
if __name__ == "__main__":
    logger.info(f"Starting Flask app locally via app.run() on {APIConfig.HOST}:{APIConfig.PORT} with DEBUG={APIConfig.DEBUG}")
    app.run( host=APIConfig.HOST, port=APIConfig.PORT, debug=APIConfig.DEBUG )

logger.info("app_search.py: Module loaded completely.")

