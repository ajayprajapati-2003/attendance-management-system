import os
import datetime
from flask import Blueprint, request, jsonify
import bcrypt
import jwt
from db import get_db_connection

auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json() or {}
    email = data.get('email', '').strip().lower()
    password = data.get('password', '')

    if not email or not password:
        return jsonify({'error': 'Email and password are required.'}), 400

    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Check if user already exists
        cursor.execute("SELECT id FROM users WHERE email = %s;", (email,))
        existing_user = cursor.fetchone()

        if existing_user:
            cursor.close()
            return jsonify({'error': 'User with this email already exists.'}), 409

        # Hash password using bcrypt
        password_bytes = password.encode('utf-8')
        hashed_password = bcrypt.hashpw(password_bytes, bcrypt.gensalt()).decode('utf-8')

        # Insert new user with default role 'employee'
        cursor.execute(
            """
            INSERT INTO users (email, password_hash, role)
            VALUES (%s, %s, %s)
            RETURNING id, email, role, created_at;
            """,
            (email, hashed_password, 'employee')
        )
        new_user = cursor.fetchone()

        # Insert corresponding employee record
        first_name = data.get('first_name', '').strip() or email.split('@')[0].capitalize()
        last_name = data.get('last_name', '').strip() or 'Employee'
        cursor.execute(
            """
            INSERT INTO employees (user_id, first_name, last_name, is_active)
            VALUES (%s, %s, %s, true);
            """,
            (new_user['id'], first_name, last_name)
        )
        conn.commit()
        cursor.close()

        return jsonify({
            'message': 'User registered successfully.',
            'user': {
                'id': new_user['id'],
                'email': new_user['email'],
                'role': new_user['role'],
                'created_at': str(new_user['created_at'])
            }
        }), 201

    except Exception as e:
        if conn:
            conn.rollback()
        return jsonify({'error': f'Registration failed: {str(e)}'}), 500
    finally:
        if conn:
            conn.close()


@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    email = data.get('email', '').strip().lower()
    password = data.get('password', '')

    if not email or not password:
        return jsonify({'error': 'Email and password are required.'}), 400

    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Fetch user by email
        cursor.execute(
            "SELECT id, email, password_hash, role FROM users WHERE email = %s;",
            (email,)
        )
        user = cursor.fetchone()
        cursor.close()

        if not user:
            return jsonify({'error': 'Invalid email or password.'}), 401

        # Verify password with bcrypt
        provided_password_bytes = password.encode('utf-8')
        stored_hash_bytes = user['password_hash'].encode('utf-8')

        if not bcrypt.checkpw(provided_password_bytes, stored_hash_bytes):
            return jsonify({'error': 'Invalid email or password.'}), 401

        # Generate JWT Token with 24 hours expiration
        jwt_secret = os.getenv("JWT_SECRET_KEY", "super-secret-key-change-this")
        payload = {
            'user_id': user['id'],
            'email': user['email'],
            'role': user['role'],
            'exp': datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(hours=24),
            'iat': datetime.datetime.now(datetime.timezone.utc)
        }
        token = jwt.encode(payload, jwt_secret, algorithm='HS256')

        return jsonify({
            'message': 'Login successful.',
            'token': token,
            'user_id': user['id'],
            'role': user['role']
        }), 200

    except Exception as e:
        return jsonify({'error': f'Login failed: {str(e)}'}), 500
    finally:
        if conn:
            conn.close()
