import os
from flask import Flask, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import psycopg2
from routes.auth_routes import auth_bp
from routes.attendance_routes import attendance_bp

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)
CORS(app)

# App configuration
app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "super-secret-key-change-this")

# Register Blueprints
app.register_blueprint(auth_bp, url_prefix="/api/auth")
app.register_blueprint(attendance_bp, url_prefix="/api/attendance")


@app.route("/", methods=["GET"])
def index():
    return jsonify({
        "status": "online",
        "message": "Attendance Management System API is running successfully",
        "documentation": {
            "health_check": "/api/health",
            "auth": {
                "register": "POST /api/auth/register",
                "login": "POST /api/auth/login",
                "profile": "GET /api/auth/profile"
            },
            "attendance": {
                "clock_in": "POST /api/attendance/clock-in",
                "clock_out": "POST /api/attendance/clock-out",
                "today_status": "GET /api/attendance/today",
                "history": "GET /api/attendance/history",
                "summary": "GET /api/attendance/summary"
            }
        }
    }), 200


@app.route("/api/health", methods=["GET"])
def health_check():
    database_url = os.getenv("DATABASE_URL")

    if not database_url or database_url == "YOUR_SUPABASE_CONNECTION_STRING_HERE":
        return jsonify({
            "status": "error",
            "database": "disconnected",
            "message": "DATABASE_URL is not configured in .env"
        }), 500

    try:
        # Establish a database connection and run test query
        conn = psycopg2.connect(database_url)
        cursor = conn.cursor()
        cursor.execute("SELECT 1;")
        cursor.fetchone()
        cursor.close()
        conn.close()

        return jsonify({
            "status": "success",
            "database": "connected",
            "message": "Database connection test successful."
        }), 200
    except Exception as e:
        return jsonify({
            "status": "error",
            "database": "disconnected",
            "error": str(e)
        }), 500


if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=True)
