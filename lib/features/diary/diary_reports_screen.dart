import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/animated_interactive_card.dart';

import '../../core/services/api_service.dart';
import 'package:provider/provider.dart';

class DiaryReportsScreen extends StatefulWidget {
  const DiaryReportsScreen({super.key});

  @override
  State<DiaryReportsScreen> createState() => _DiaryReportsScreenState();
}

class _DiaryReportsScreenState extends State<DiaryReportsScreen> {
  bool _isSending = false;

  Future<void> _sendToGov(String reportId) async {
    setState(() => _isSending = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final success = await apiService.sendReportToGov(reportId, 'subsidy@government.in');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Report submitted to government successfully!' : 'Failed to submit report.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
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
            Text('Farm Reports', style: AppTextStyles.sectionLabel),
            Text('Compliance & Traceability', style: AppTextStyles.caption),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildComplianceBanner(),
                const SizedBox(height: 16),
                _buildSubsidyLinkCard(),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RECENT REPORTS', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(LucideIcons.fileDown, size: 16),
                      label: Text('Export All', style: AppTextStyles.label.copyWith(fontSize: 12, color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildReportItem('April 2026 Monthly Report', 'REP-001', 'Generated 2 hours ago', 'Ready'),
                _buildReportItem('Irrigation Compliance V2', 'REP-002', 'April 15, 2026', 'Verified'),
                _buildReportItem('March 2026 Summary', 'REP-003', 'April 02, 2026', 'Archived'),
                _buildReportItem('Chemical Application Log', 'REP-004', 'March 28, 2026', 'Ready'),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isSending)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildComplianceBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.healthGradient,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('COMPLIANCE', style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 14, letterSpacing: 1.5)),
              const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 20),
          Text('100% Traceable', style: AppTextStyles.dataDisplay.copyWith(color: Colors.white, fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            'Your farm logs meet GlobalGAP standards for irrigation and nutrient management.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.fileText, size: 18),
              label: const Text('Download Traceability PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubsidyLinkCard() {
    return AnimatedInteractiveCard(
      onTap: () => context.push('/farm/diary/subsidy'),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.timer, color: AppColors.accentOrange, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subsidy Tracking', style: AppTextStyles.label.copyWith(fontSize: 16)),
                Text('Track pending government payments', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }

  Widget _buildReportItem(String title, String id, String date, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.fileText, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.label.copyWith(fontSize: 16)),
                    Text(date, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'Ready' ? AppColors.accentBlue.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.caption.copyWith(
                    color: status == 'Ready' ? AppColors.accentBlue : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.download, size: 16),
                  label: const Text('Download'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _sendToGov(id),
                  icon: const Icon(LucideIcons.send, size: 16),
                  label: const Text('Send to Gov'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
