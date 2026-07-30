import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

import '../../core/services/api_service.dart';
import 'package:intl/intl.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _apiService = ApiService();
  List<dynamic> _alerts = [];
  bool _isLoading = true;
  bool _hasError = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _silentPoll();
    });
  }

  Future<void> _silentPoll() async {
    try {
      final res = await _apiService.getAlerts();
      if (mounted) {
        setState(() {
          _alerts = res;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Alerts silent poll error: $e');
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final res = await _apiService.getAlerts();
      if (mounted) {
        setState(() {
          _alerts = res;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Alerts load error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final criticalCount = _alerts.where((a) => _getAlertType(a['type']) == 'critical').length;
    // warningCount computed if needed

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notifications & Alerts', style: AppTextStyles.sectionLabel),
            Text(
              criticalCount > 0
                  ? '$criticalCount Critical · ${_alerts.length} Total'
                  : '${_alerts.length} Total Alerts',
              style: AppTextStyles.caption.copyWith(
                color: criticalCount > 0 ? AppColors.accentRed : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(LucideIcons.refreshCw, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorState()
              : _alerts.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: _alerts.length,
                        itemBuilder: (context, index) {
                          final alert = _alerts[index];
                          final timestamp = alert['timestamp'] != null
                              ? DateTime.parse(alert['timestamp']).toLocal()
                              : DateTime.now();

                          final alertType = _getAlertType(alert['type']);
                          final isNew = index < 3; // Top 3 highlighted as new

                          return _buildAlertItem(
                            title: alert['title'] ?? 'System Update',
                            desc: alert['description'] ?? '',
                            time: _getTimeAgo(timestamp),
                            type: alertType,
                            isNew: isNew,
                          );
                        },
                      ),
                    ),
    );
  }

  String _getTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM dd, HH:mm').format(dt);
  }

  String _getAlertType(String? type) {
    if (type == null) return 'info';
    final t = type.toLowerCase();
    if (t.contains('anomaly') ||
        t.contains('critical') ||
        t.contains('failure') ||
        t.contains('node_failure') ||
        t.contains('delivery_failure')) {
      return 'critical';
    }
    if (t.contains('low') ||
        t.contains('warning') ||
        t.contains('battery_low') ||
        t.contains('virtual_sensing')) {
      return 'warning';
    }
    return 'info';
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.accentRed),
            const SizedBox(height: 16),
            Text('Failed to load notifications', style: AppTextStyles.label),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.shieldCheck,
              size: 64, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('All Systems Normal',
              style: AppTextStyles.label.copyWith(color: AppColors.textPrimary, fontSize: 18)),
          const SizedBox(height: 6),
          Text('No active warnings or anomalies detected.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    required String title,
    required String desc,
    required String time,
    required String type,
    bool isNew = false,
  }) {
    final color = type == 'critical'
        ? AppColors.accentRed
        : type == 'warning'
            ? AppColors.accentOrange
            : AppColors.primary;
    final icon = type == 'critical'
        ? LucideIcons.alertOctagon
        : type == 'warning'
            ? LucideIcons.alertTriangle
            : LucideIcons.bell;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isNew ? color.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNew ? color.withValues(alpha: 0.3) : AppColors.border,
          width: isNew ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(time, style: AppTextStyles.caption.copyWith(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
