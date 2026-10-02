import datetime
from flask import Blueprint, request, jsonify
from db import get_db_connection
from middleware.auth_middleware import token_required

attendance_bp = Blueprint('attendance', __name__)


def _get_employee_id(cursor, user_id):
    """
    Resolves the employee_id from the employees table corresponding to user_id.
    If no employee record exists, creates a default one for this user_id.
    """
    cursor.execute(
        "SELECT id FROM employees WHERE user_id = %s OR id = %s LIMIT 1;",
        (user_id, user_id)
    )
    emp = cursor.fetchone()
    if emp:
        return emp['id']

    # Auto-provision employee record if not present
    cursor.execute(
        """
        INSERT INTO employees (user_id, first_name, last_name, is_active)
        VALUES (%s, 'Employee', 'User', true)
        RETURNING id;
        """,
        (user_id,)
    )
    new_emp = cursor.fetchone()
    return new_emp['id']


def _format_record(record):
    """Helper to convert database record dates/times to strings for JSON serialization."""
    if not record:
        return None

    clock_in = record.get('clock_in_time')
    clock_out = record.get('clock_out_time')

    return {
        'id': str(record.get('id')) if record.get('id') is not None else None,
        'employee_id': str(record.get('employee_id')) if record.get('employee_id') is not None else None,
        'date': str(record.get('date')) if record.get('date') is not None else None,
        'clock_in_time': clock_in.isoformat() if isinstance(clock_in, (datetime.datetime, datetime.time, datetime.date)) else (str(clock_in) if clock_in else None),
        'clock_in_lat': float(record['clock_in_lat']) if record.get('clock_in_lat') is not None else None,
        'clock_in_lng': float(record['clock_in_lng']) if record.get('clock_in_lng') is not None else None,
        'clock_out_time': clock_out.isoformat() if isinstance(clock_out, (datetime.datetime, datetime.time, datetime.date)) else (str(clock_out) if clock_out else None),
        'clock_out_lat': float(record['clock_out_lat']) if record.get('clock_out_lat') is not None else None,
        'clock_out_lng': float(record['clock_out_lng']) if record.get('clock_out_lng') is not None else None,
        'status': record.get('status', 'Present')
    }


@attendance_bp.route('/clock-in', methods=['POST'])
@token_required
def clock_in(user_id):
    """
    Clock in for today with GPS coordinates.
    """
    data = request.get_json() or {}
    latitude = data.get('latitude')
    longitude = data.get('longitude')

    current_date = datetime.date.today()
    current_timestamp = datetime.datetime.now(datetime.timezone.utc)

    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        employee_id = _get_employee_id(cursor, user_id)

        # Check if already clocked in today
        cursor.execute(
            """
            SELECT id, employee_id, date, clock_in_time, clock_in_lat, clock_in_lng,
                   clock_out_time, clock_out_lat, clock_out_lng, status
            FROM attendance
            WHERE employee_id = %s AND date = %s;
            """,
            (employee_id, current_date)
        )
        existing_record = cursor.fetchone()

        if existing_record and existing_record.get('clock_in_time'):
            cursor.close()
            return jsonify({
                'message': 'You have already clocked in for today.',
                'record': _format_record(existing_record),
                'attendance': _format_record(existing_record)
            }), 400

        # Insert new attendance record
        cursor.execute(
            """
            INSERT INTO attendance (employee_id, date, clock_in_time, clock_in_lat, clock_in_lng, status)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING id, employee_id, date, clock_in_time, clock_in_lat, clock_in_lng,
                      clock_out_time, clock_out_lat, clock_out_lng, status;
            """,
            (employee_id, current_date, current_timestamp, latitude, longitude, 'Present')
        )
        new_record = cursor.fetchone()
        conn.commit()
        cursor.close()

        return jsonify({
            'message': 'Clocked in successfully.',
            'record': _format_record(new_record),
            'attendance': _format_record(new_record)
        }), 201

    except Exception as e:
        if conn:
            conn.rollback()
        return jsonify({'error': f'Clock-in failed: {str(e)}'}), 500
    finally:
        if conn:
            conn.close()


@attendance_bp.route('/clock-out', methods=['POST'])
@token_required
def clock_out(user_id):
    """
    Clock out for today:
    - Finds existing attendance record for employee_id where date is current date and clock_out_time is NULL.
    - Updates record with clock_out_time, clock_out_lat, and clock_out_lng.
    - Returns success message and the updated record.
    """
    data = request.get_json() or {}
    latitude = data.get('latitude')
    longitude = data.get('longitude')

    current_date = datetime.date.today()
    current_timestamp = datetime.datetime.now(datetime.timezone.utc)

    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        employee_id = _get_employee_id(cursor, user_id)

        # Find existing attendance record for today where clock_out_time is NULL
        cursor.execute(
            """
            SELECT id, employee_id, date, clock_in_time, clock_in_lat, clock_in_lng,
                   clock_out_time, clock_out_lat, clock_out_lng, status
            FROM attendance
            WHERE employee_id = %s AND date = %s AND clock_out_time IS NULL;
            """,
            (employee_id, current_date)
        )
        existing_record = cursor.fetchone()

        if not existing_record:
            # Check if user already clocked out or never clocked in
            cursor.execute(
                """
                SELECT id, clock_in_time, clock_out_time
                FROM attendance
                WHERE employee_id = %s AND date = %s;
                """,
                (employee_id, current_date)
            )
            today_record = cursor.fetchone()
            cursor.close()

            if today_record and today_record.get('clock_out_time'):
                return jsonify({'error': 'You have already clocked out for today.'}), 400
            return jsonify({'error': 'No active clock-in record found for today. Please clock in first.'}), 400

        # Update clock-out time and coordinates
        cursor.execute(
            """
            UPDATE attendance
            SET clock_out_time = %s, clock_out_lat = %s, clock_out_lng = %s
            WHERE id = %s
            RETURNING id, employee_id, date, clock_in_time, clock_in_lat, clock_in_lng,
                      clock_out_time, clock_out_lat, clock_out_lng, status;
            """,
            (current_timestamp, latitude, longitude, existing_record['id'])
        )
        updated_record = cursor.fetchone()
        conn.commit()
        cursor.close()

        formatted = _format_record(updated_record)
        return jsonify({
            'message': 'Clocked out successfully.',
            'record': formatted,
            'attendance': formatted
        }), 200

    except Exception as e:
        if conn:
            conn.rollback()
        return jsonify({'error': f'Clock-out failed: {str(e)}'}), 500
    finally:
        if conn:
            conn.close()


@attendance_bp.route('/today', methods=['GET'])
@token_required
def get_today_attendance(user_id):
    """
    Fetch attendance record for the logged-in user for the current date.
    Returns clock_in_time, clock_out_time, and status.
    If no record exists for today, returns {"status": "Not Checked In"}.
    """
    current_date = datetime.date.today()
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        employee_id = _get_employee_id(cursor, user_id)

        cursor.execute(
            """
            SELECT id, employee_id, date, clock_in_time, clock_in_lat, clock_in_lng,
                   clock_out_time, clock_out_lat, clock_out_lng, status
            FROM attendance
            WHERE employee_id = %s AND date = %s;
            """,
            (employee_id, current_date)
        )
        record = cursor.fetchone()
        cursor.close()

        if not record:
            return jsonify({
                'status': 'Not Checked In',
                'message': 'No attendance record found for today.',
                'clock_in_time': None,
                'clock_out_time': None,
                'record': None,
                'attendance': None
            }), 200

        formatted_record = _format_record(record)
        status = "Checked Out" if record.get('clock_out_time') else "Checked In"

        return jsonify({
            'status': status,
            'clock_in_time': formatted_record.get('clock_in_time'),
            'clock_out_time': formatted_record.get('clock_out_time'),
            'record': formatted_record,
            'attendance': formatted_record
        }), 200

    except Exception as e:
        return jsonify({'error': f'Failed to fetch today\'s attendance: {str(e)}'}), 500
    finally:
        if conn:
            conn.close()


@attendance_bp.route('/history', methods=['GET'])
@token_required
def get_attendance_history(user_id):
    """
    Fetch all attendance records for the logged-in user from the attendance table,
    ordered by date descending.
    Returns a JSON list of records.
    """
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        employee_id = _get_employee_id(cursor, user_id)

        cursor.execute(
            """
            SELECT id, employee_id, date, clock_in_time, clock_in_lat, clock_in_lng,
                   clock_out_time, clock_out_lat, clock_out_lng, status
            FROM attendance
            WHERE employee_id = %s
            ORDER BY date DESC, clock_in_time DESC;
            """,
            (employee_id,)
        )
        records = cursor.fetchall()
        cursor.close()

        formatted_records = [_format_record(r) for r in records]
        return jsonify({
            'records': formatted_records,
            'history': formatted_records
        }), 200

    except Exception as e:
        return jsonify({'error': f'Failed to fetch attendance history: {str(e)}'}), 500
    finally:
        if conn:
            conn.close()
