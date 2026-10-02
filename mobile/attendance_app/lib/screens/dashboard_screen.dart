import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../services/attendance_service.dart';
import '../utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isCheckedIn = false;
  String _checkInTime = "--:--";
  String _checkOutTime = "--:--";
  String _status = "Not Checked In";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTodayAttendance();
  }

  String _formatTimeDisplay(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty || timeStr == "--:--") {
      return "--:--";
    }
    try {
      if (timeStr.contains('AM') || timeStr.contains('PM')) {
        return timeStr;
      }
      if (timeStr.contains('T') || timeStr.contains(' ') || timeStr.contains('-')) {
        final parsed = DateTime.tryParse(timeStr);
        if (parsed != null) {
          final local = parsed.toLocal();
          int hour = local.hour;
          int minute = local.minute;
          final period = hour >= 12 ? 'PM' : 'AM';
          final formattedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
          final formattedMinute = minute.toString().padLeft(2, '0');
          return '$formattedHour:$formattedMinute $period';
        }
      }
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final formattedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final formattedMinute = minute.toString().padLeft(2, '0');
        return '$formattedHour:$formattedMinute $period';
      }
    } catch (_) {}
    return timeStr;
  }

  Future<void> _loadTodayAttendance() async {
    try {
      final data = await _attendanceService.getTodayAttendance();
      if (data != null && mounted) {
        final att = data['attendance'] as Map<String, dynamic>? ??
            (data['record'] as Map<String, dynamic>? ?? data);
        final clockIn = att['clock_in_time'] as String? ?? data['clock_in_time'] as String?;
        final clockOut = att['clock_out_time'] as String? ?? data['clock_out_time'] as String?;
        final statusStr = data['status'] as String? ?? att['status'] as String? ?? 'Not Checked In';

        setState(() {
          if (clockIn != null && clockIn.isNotEmpty) {
            _checkInTime = _formatTimeDisplay(clockIn);
            if (clockOut != null && clockOut.isNotEmpty) {
              _checkOutTime = _formatTimeDisplay(clockOut);
              _isCheckedIn = false;
              _status = "Checked Out";
            } else {
              _checkOutTime = "--:--";
              _isCheckedIn = true;
              _status = "Checked In";
            }
          } else {
            _checkInTime = "--:--";
            _checkOutTime = "--:--";
            _isCheckedIn = false;
            _status = statusStr;
          }
        });
      }
    } catch (_) {
      // Keep defaults if initial fetch fails
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    return '$weekday, ${now.day} $month';
  }

  Future<void> _handleAttendance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Check Location Service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showSnackBar(
            'Location services are disabled. Please enable GPS in device settings.',
            AppColors.error,
          );
        }
        return;
      }

      // 2. Check & Request Location Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showSnackBar(
              'Location permission denied. Cannot record attendance without GPS.',
              AppColors.error,
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showSnackBar(
            'Location permissions are permanently denied. Please enable in app settings.',
            AppColors.error,
          );
        }
        return;
      }

      // 3. Acquire Current GPS Coordinates
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // 4. Send Clock-In or Clock-Out Request
      if (_isCheckedIn) {
        await _attendanceService.clockOut(position.latitude, position.longitude);
        _showSnackBar('Clocked Out Successfully!', AppColors.warning);
      } else {
        await _attendanceService.clockIn(position.latitude, position.longitude);
        _showSnackBar('Clocked In Successfully!', AppColors.success);
      }

      // 5. Refresh today's attendance data from backend
      await _loadTodayAttendance();
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      _showSnackBar(errorMsg, AppColors.error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _getFormattedDate();
    final buttonColor = _isCheckedIn ? AppColors.warning : AppColors.primaryColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.access_time_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Attendance Portal',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _loadTodayAttendance(),
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLarge,
            vertical: AppDimensions.paddingMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Section: Greeting & Date
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                formattedDate,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Middle Section: Dynamic Clock In / Clock Out Button
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        boxShadow: [
                          BoxShadow(
                            color: buttonColor.withValues(alpha: 0.18),
                            blurRadius: 36,
                            spreadRadius: 8,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Material(
                          color: buttonColor,
                          shape: const CircleBorder(),
                          elevation: 6,
                          shadowColor: buttonColor.withValues(alpha: 0.4),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _isLoading ? null : _handleAttendance,
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3.5,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isCheckedIn
                                              ? Icons.logout_rounded
                                              : Icons.touch_app_rounded,
                                          size: 54,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _isCheckedIn ? 'Clock Out' : 'Clock In',
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _isCheckedIn
                                              ? 'Tap to complete shift'
                                              : 'Tap with GPS location',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.white.withValues(alpha: 0.8),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCheckedIn ? AppColors.warning : AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isCheckedIn ? 'Active Shift in Progress' : 'Ready to Clock In',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Bottom Section: Today's Attendance Summary Card
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Today's Summary",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (_isCheckedIn
                                    ? AppColors.warning
                                    : (_status == "Checked Out"
                                        ? AppColors.primary
                                        : AppColors.textSecondary))
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _status,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isCheckedIn
                                  ? AppColors.warning
                                  : (_status == "Checked Out"
                                      ? AppColors.primary
                                      : AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // Check In Box
                        Expanded(
                          child: _buildTimeMetric(
                            title: 'Check-In',
                            time: _checkInTime,
                            icon: Icons.login_rounded,
                            iconColor: AppColors.success,
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: AppColors.border,
                        ),
                        // Check Out Box
                        Expanded(
                          child: _buildTimeMetric(
                            title: 'Check-Out',
                            time: _checkOutTime,
                            icon: Icons.logout_rounded,
                            iconColor: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeMetric({
    required String title,
    required String time,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
