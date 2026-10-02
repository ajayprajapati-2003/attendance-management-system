-- Attendance Management System - Database Schema (PostgreSQL / Supabase)

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Departments Table
CREATE TABLE IF NOT EXISTS departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 2. Office Locations Table (Geofencing)
CREATE TABLE IF NOT EXISTS office_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    latitude NUMERIC NOT NULL,
    longitude NUMERIC NOT NULL,
    radius_meters INTEGER NOT NULL,
    address TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 3. Users Table (Authentication)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'employee',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 4. Employees Table (Profile & KYC)
CREATE TABLE IF NOT EXISTS employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(50),
    designation VARCHAR(100) DEFAULT 'Software Engineer',
    is_active BOOLEAN DEFAULT true,
    kyc_aadhaar VARCHAR(50),
    kyc_pan VARCHAR(50),
    kyc_driving_license VARCHAR(50),
    kyc_voter_id VARCHAR(50),
    kyc_uan VARCHAR(50),
    kyc_verified BOOLEAN DEFAULT false,
    face_verified BOOLEAN DEFAULT false,
    bank_name VARCHAR(100) DEFAULT 'HDFC Bank',
    bank_account_no VARCHAR(100) DEFAULT '50100234567890',
    bank_ifsc VARCHAR(50) DEFAULT 'HDFC0001234',
    monthly_salary NUMERIC(12, 2) DEFAULT 25000.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 5. Attendance Table (Clock In / Out logs)
CREATE TABLE IF NOT EXISTS attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
    office_id UUID REFERENCES office_locations(id) ON DELETE SET NULL,
    date DATE NOT NULL,
    clock_in_time TIMESTAMP WITH TIME ZONE,
    clock_in_lat NUMERIC,
    clock_in_lng NUMERIC,
    clock_out_time TIMESTAMP WITH TIME ZONE,
    clock_out_lat NUMERIC,
    clock_out_lng NUMERIC,
    status VARCHAR(50) DEFAULT 'PRESENT',
    selfie_url TEXT,
    is_geofenced BOOLEAN DEFAULT true,
    geofence_distance_meters NUMERIC DEFAULT 0,
    approval_status VARCHAR(50) DEFAULT 'Approved',
    approval_remarks TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date ON attendance(employee_id, date);
CREATE INDEX IF NOT EXISTS idx_employees_user_id ON employees(user_id);
CREATE INDEX IF NOT EXISTS idx_employees_department_id ON employees(department_id);
CREATE INDEX IF NOT EXISTS idx_attendance_office_id ON attendance(office_id);
