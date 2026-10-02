import os
from functools import wraps
from flask import request, jsonify
import jwt


def token_required(f):
    """
    Decorator to protect routes by validating JWT Bearer tokens
    and passing the extracted user_id to the route handler.
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        auth_header = request.headers.get("Authorization")

        if auth_header:
            parts = auth_header.split()
            if len(parts) == 2 and parts[0].lower() == "bearer":
                token = parts[1]
            elif len(parts) == 1:
                token = parts[0]

        if not token:
            return jsonify({
                "error": "Authentication token is missing. Please provide Authorization: Bearer <token>."
            }), 401

        try:
            jwt_secret = os.getenv("JWT_SECRET_KEY", "super-secret-key-change-this")
            payload = jwt.decode(token, jwt_secret, algorithms=["HS256"])
            user_id = payload.get("user_id")

            if not user_id:
                return jsonify({"error": "Invalid token payload: user_id missing."}), 401

        except jwt.ExpiredSignatureError:
            return jsonify({"error": "Token has expired. Please log in again."}), 401
        except jwt.InvalidTokenError as e:
            return jsonify({"error": f"Invalid authentication token: {str(e)}"}), 401
        except Exception as e:
            return jsonify({"error": f"Authentication failed: {str(e)}"}), 401

        return f(user_id, *args, **kwargs)

    return decorated
