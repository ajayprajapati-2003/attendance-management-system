import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

load_dotenv()


def get_db_connection():
    """
    Establishes and returns a connection to the PostgreSQL/Supabase database.
    """
    database_url = os.getenv("DATABASE_URL")
    if not database_url or database_url == "YOUR_SUPABASE_CONNECTION_STRING_HERE":
        raise ValueError("DATABASE_URL is not properly configured in .env file.")

    try:
        connection = psycopg2.connect(
            database_url,
            cursor_factory=RealDictCursor
        )
        return connection
    except Exception as error:
        print(f"[Database Error] Connection failed: {error}")
        raise error
