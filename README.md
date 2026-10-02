# Attendance Management System

A full-stack attendance management system with a Python Flask REST API backend, PostgreSQL / Supabase database, and a cross-platform Flutter application (Web, Android, Desktop).

---

## System Architecture

```text
├── backend/                  # Python Flask REST API
│   ├── routes/              # Auth & Attendance endpoints
│   ├── middleware/          # JWT verification middleware
│   ├── db.py                # Database connection utility
│   ├── run.py               # Flask application entry point
│   ├── requirements.txt     # Python dependencies
│   ├── schema.sql           # Database schema & indexes
│   └── .env                 # Environment variables
│
└── mobile/attendance_app/   # Flutter cross-platform client
    ├── lib/
    │   ├── screens/         # UI screens (Login, Register, Dashboard, History, Profile)
    │   ├── services/        # API services (AuthService, AttendanceService)
    │   └── utils/           # Colors, themes, and API baseUrl configuration
    └── android/             # Android build & Gradle configuration
```

---

## 1. Database Setup (PostgreSQL / Supabase)

1. Open your PostgreSQL console, psql, or [Supabase SQL Editor](https://supabase.com).
2. Execute the schema script located at `backend/schema.sql` to initialize the required tables:
   - `users`: User credentials, roles, and hashed passwords.
   - `employees`: Employee profile records linked to users.
   - `attendance`: Clock-in/out logs, timestamps, status, and GPS coordinates.
3. Configure your database connection string in `backend/.env`:
   ```env
   DATABASE_URL=postgresql://<user>:<password>@<host>:<port>/<database>
   JWT_SECRET_KEY=your-secure-jwt-secret
   PORT=5000
   ```

---

## 2. Running the Backend (Flask API)

1. Open a PowerShell terminal and navigate to `backend`:
   ```powershell
   cd d:\attendance-management-system\backend
   ```

2. Activate the virtual environment:
   ```powershell
   .\.venv\Scripts\Activate.ps1
   ```
   *(If your execution policy blocks activation, run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` first)*

3. Verify dependencies are installed:
   ```powershell
   pip install -r requirements.txt
   ```

4. Start the Flask server:
   ```powershell
   python run.py
   ```
   The backend will start at `http://localhost:5000`.

5. Check server health by visiting:
   ```text
   http://localhost:5000/api/health
   ```

---

## 3. Running the Flutter App

1. Open a second PowerShell terminal and navigate to the Flutter project:
   ```powershell
   cd d:\attendance-management-system\mobile\attendance_app
   ```

2. Fetch dependencies:
   ```powershell
   flutter pub get
   ```

3. Choose your target platform:

   ### Option A: Web (Chrome - Recommended for quick testing)
   ```powershell
   flutter run -d chrome
   ```

   ### Option B: Windows Desktop
   ```powershell
   flutter run -d windows
   ```

   ### Option C: Android (Emulator or Physical Device)
   - Start an Android emulator or connect a device with USB debugging enabled.
   - Run:
     ```powershell
     flutter run -d android
     ```

---

## API Configuration for Different Devices

Network configurations are located in `mobile/attendance_app/lib/utils/constants.dart`:
- **Web / Desktop**: Uses `http://localhost:5000/api`
- **Android Emulator**: Uses `http://10.0.2.2:5000/api` (Android's alias to host `localhost`)
- **Physical Mobile Device**: Set `baseUrl` to your computer's local Wi-Fi IP address (e.g. `http://192.168.1.50:5000/api`) and ensure your mobile device is on the same network.
