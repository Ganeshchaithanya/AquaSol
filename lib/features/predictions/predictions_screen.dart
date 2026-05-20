import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

import '../../core/services/api_service.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _farmName = 'Patel Orchards';
  List<dynamic> _predictions = [];

  @override
  void initState() {
    super.initState();
    _fetchPredictions();
  }

  Future<void> _fetchPredictions() async {
    final data = await _apiService.getPredictions();
    if (data != null && mounted) {
      setState(() {
        _farmName = data['farm_name'] ?? 'Patel Orchards';
        _predictions = data['predictions'] ?? [];
        _isLoading = false;
      });
    } else {
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
            Text('AI Predictions', style: AppTextStyles.sectionLabel),
            Text('$_farmName · ${_predictions.length} Active Alerts', style: AppTextStyles.caption),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _predictions.isEmpty 
          ? Center(child: Text('No active predictions.', style: AppTextStyles.bodyMedium))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final pred = _predictions[index];
                return _buildPredictionCard(
                  type: pred['type'],
                  title: pred['title'],
                  desc: pred['desc'],
                  confidence: pred['confidence'],
                  category: pred['category'],
                );
              },
            ),
    );
  }

  Widget _buildPredictionCard({
    required String type,
    required String title,
    required String desc,
    required double confidence,
    required String category,
  }) {
    Gradient gradient;
    if (category == 'irrigation') {
      gradient = AppColors.aiGradient;
    } else if (category == 'stage') {
      gradient = AppColors.pnlGradient;
    } else {
      gradient = const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(27)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(type.toUpperCase(), style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Confidence', style: AppTextStyles.bodySmall),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: confidence,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(gradient.colors.first),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${(confidence * 100).toInt()}%', style: AppTextStyles.label.copyWith(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Dismiss', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Approve', style: AppTextStyles.label),
                      ),
                    ),
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
