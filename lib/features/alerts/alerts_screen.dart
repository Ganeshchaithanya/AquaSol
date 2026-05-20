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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getAlerts();
      if (mounted) {
        setState(() {
          _alerts = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Notifications', style: AppTextStyles.sectionLabel),
            Text('${_alerts.length} New Alerts', style: AppTextStyles.caption.copyWith(color: AppColors.accentRed)),
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
        : _alerts.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _alerts.length,
                itemBuilder: (context, index) {
                  final alert = _alerts[index];
                  final timestamp = alert['timestamp'] != null 
                    ? DateTime.parse(alert['timestamp']) 
                    : DateTime.now();
                  
                  return _buildAlertItem(
                    title: alert['title'] ?? 'System Update',
                    desc: alert['description'] ?? '',
                    time: _getTimeAgo(timestamp),
                    type: _getAlertType(alert['type']),
                    isNew: index < 2, // Simple logic for 'new'
                  );
                },
              ),
            ),
    );
  }

  String _getTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM dd').format(dt);
  }

  String _getAlertType(String? type) {
    if (type == null) return 'info';
    final t = type.toLowerCase();
    if (t.contains('anomaly') || t.contains('critical') || t.contains('failure') || t.contains('sensing')) return 'critical';
    if (t.contains('low') || t.contains('warning')) return 'warning';
    return 'info';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.bellOff, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No new notifications', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
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
    String? actionText,
  }) {
    final color = type == 'critical' ? AppColors.accentRed : type == 'warning' ? AppColors.accentOrange : AppColors.primary;
    final icon = type == 'critical' ? LucideIcons.alertOctagon : type == 'warning' ? LucideIcons.alertTriangle : LucideIcons.bell;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isNew ? color.withValues(alpha: 0.02) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isNew ? color.withValues(alpha: 0.2) : AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
                    if (isNew)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                if (actionText != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(actionText, style: AppTextStyles.label.copyWith(color: color, fontSize: 12)),
                        const SizedBox(width: 8),
                        Icon(LucideIcons.chevronRight, color: color, size: 14),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(time, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
