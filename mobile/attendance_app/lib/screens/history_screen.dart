import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/attendance_service.dart';
import '../utils/constants.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  late Future<List<dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = _attendanceService.getHistory();
    });
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return "--";
    try {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
      }
    } catch (_) {}
    return rawDate;
  }

  String _formatTime(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty || rawTime == "--:--") {
      return "--:--";
    }
    try {
      if (rawTime.contains('AM') || rawTime.contains('PM')) {
        return rawTime;
      }
      if (rawTime.contains('T') || rawTime.contains(' ') || rawTime.contains('-')) {
        final parsed = DateTime.tryParse(rawTime);
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
      final parts = rawTime.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final formattedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final formattedMinute = minute.toString().padLeft(2, '0');
        return '$formattedHour:$formattedMinute $period';
      }
    } catch (_) {}
    return rawTime;
  }

  String _calculateDuration(String? inTime, String? outTime) {
    if (inTime == null || outTime == null || inTime.isEmpty || outTime.isEmpty) {
      return "--";
    }
    try {
      DateTime? inDt = DateTime.tryParse(inTime);
      DateTime? outDt = DateTime.tryParse(outTime);
      if (inDt != null && outDt != null) {
        final diff = outDt.difference(inDt);
        if (!diff.isNegative) {
          final hours = diff.inHours;
          final minutes = diff.inMinutes.remainder(60);
          return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
        }
      }

      final inParts = inTime.split(':');
      final outParts = outTime.split(':');
      if (inParts.length >= 2 && outParts.length >= 2) {
        final inMinutes = int.parse(inParts[0]) * 60 + int.parse(inParts[1]);
        final outMinutes = int.parse(outParts[0]) * 60 + int.parse(outParts[1]);
        final diff = outMinutes - inMinutes;
        if (diff >= 0) {
          final hours = diff ~/ 60;
          final minutes = diff % 60;
          return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
        }
      }
    } catch (_) {}
    return "--";
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
      case 'checked out':
        return AppColors.success;
      case 'checked in':
      case 'late':
        return AppColors.warning;
      case 'half day':
        return AppColors.primaryLight;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Attendance History',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Refresh History',
            onPressed: _loadHistory,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load history',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString().replaceAll('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadHistory,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return Center(
              child: RefreshIndicator(
                onRefresh: () async => _loadHistory(),
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.history_toggle_off_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Attendance Records Yet',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'When you clock in and out, your attendance history will be listed here.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadHistory(),
            color: AppColors.primary,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLarge,
                vertical: AppDimensions.paddingMedium,
              ),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final dynamic item = records[index];
                final record = item is Map<String, dynamic> ? item : <String, dynamic>{};

                final rawDate = record['date']?.toString();
                final rawClockIn = record['clock_in_time']?.toString();
                final rawClockOut = record['clock_out_time']?.toString();
                final status = record['status']?.toString() ?? (rawClockOut != null ? 'Present' : 'Checked In');

                final dateText = _formatDate(rawDate);
                final checkInText = _formatTime(rawClockIn);
                final checkOutText = _formatTime(rawClockOut);
                final durationText = _calculateDuration(rawClockIn, rawClockOut);
                final statusColor = _getStatusColor(status);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                    child: Column(
                      children: [
                        // Top Row: Date & Status Chip
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  dateText,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 12),

                        // Bottom Row: Metrics
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTimeItem(
                              label: 'Check In',
                              time: checkInText,
                              icon: Icons.login_rounded,
                              color: AppColors.success,
                            ),
                            _buildTimeItem(
                              label: 'Check Out',
                              time: checkOutText,
                              icon: Icons.logout_rounded,
                              color: AppColors.error,
                            ),
                            _buildTimeItem(
                              label: 'Total Hours',
                              time: durationText,
                              icon: Icons.timer_outlined,
                              color: AppColors.primaryLight,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeItem({
    required String label,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
