import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';

class CropStageScreen extends StatefulWidget {
  final String zoneId;
  const CropStageScreen({super.key, required this.zoneId});

  @override
  State<CropStageScreen> createState() => _CropStageScreenState();
}

class _CropStageScreenState extends State<CropStageScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _stageData;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final bio = await _apiService.getBiology(widget.zoneId);
      if (mounted) setState(() => _stageData = bio);
    } catch (e) {
      debugPrint('Stage load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final d = _stageData ?? {};
    final cropType = (d['crop_type'] as String? ?? 'Unknown');
    final season = (d['season'] as String? ?? '').toUpperCase();
    final dap = d['dap'] as int? ?? 0;
    final growthStage = d['growth_stage'] as String? ?? 'Unknown';
    final stageIndex = d['stage_index'] as int? ?? 1;
    final totalStages = d['total_stages'] as int? ?? 5;
    final growthPct = (d['growth_progress_pct'] as num?)?.toDouble() ?? 0.0;
    final stageSensitive = d['stage_sensitive'] as bool? ?? false;
    final irrigFreq = d['irrigation_frequency'] as String? ?? 'As needed';
    final stages = (d['stages'] as List<dynamic>?) ?? [];

    // Find the next stage after current
    final currentStageMap = stages.firstWhere(
      (s) => s['is_current'] == true,
      orElse: () => <String, dynamic>{},
    );
    final daysRemaining = currentStageMap['days_remaining'] as int?;

    // Next stage
    final currentIdx = stages.indexWhere((s) => s['is_current'] == true);
    final nextStage = (currentIdx >= 0 && currentIdx + 1 < stages.length)
        ? stages[currentIdx + 1] as Map<String, dynamic>
        : null;

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
            Text('Crop Stage', style: AppTextStyles.sectionLabel),
            Text('$cropType · $season · DAP $dap', style: AppTextStyles.caption),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildStageHeader(cropType, growthStage, stageIndex, totalStages, dap, growthPct, stageSensitive, irrigFreq),
              const SizedBox(height: 32),
              Text('GROWTH TIMELINE', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 24),
              if (stages.isEmpty)
                _buildNoDataCard(cropType)
              else
                ...stages.asMap().entries.map((e) {
                  final s = e.value as Map<String, dynamic>;
                  final isLast = e.key == stages.length - 1;
                  return _buildTimelineItem(s, isLast);
                }),
              const SizedBox(height: 32),
              _buildPredictionCard(growthStage, nextStage, daysRemaining, stageSensitive),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageHeader(String crop, String stage, int stageIdx, int total,
      int dap, double pct, bool sensitive, String irrigFreq) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.healthGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stage.toUpperCase(),
                      style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 15, letterSpacing: 2)),
                  Text(crop,
                      style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.7))),
                ],
              ),
              if (sensitive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('💧 Water Critical',
                      style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              else
                const Icon(LucideIcons.flower2, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Stage $stageIdx',
                  style: AppTextStyles.dataDisplay.copyWith(color: Colors.white, fontSize: 42)),
              const SizedBox(width: 10),
              Text('of $total',
                  style: AppTextStyles.label.copyWith(color: Colors.white.withValues(alpha: 0.6))),
            ],
          ),
          const SizedBox(height: 6),
          Text('DAP $dap · ${(dap / 7).floor()} weeks into cycle',
              style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 16),
          // Progress bar
          Row(
            children: [
              Text('Cycle Progress', style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.7))),
              const Spacer(),
              Text('${pct.toStringAsFixed(1)}%', style: AppTextStyles.caption.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Irrigation: $irrigFreq',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard(String crop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'No stage timeline found for "$crop". Set the crop type and season in your zone settings to enable stage tracking.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> stage, bool isLast) {
    final bool isDone = stage['is_done'] as bool? ?? false;
    final bool isCurrent = stage['is_current'] as bool? ?? false;
    final String name = stage['name'] as String? ?? '';
    final int dStart = stage['days_start'] as int? ?? 0;
    final int dEnd = stage['days_end'] as int? ?? 0;
    final int? daysLeft = stage['days_remaining'] as int?;
    final String irrigFreq = stage['irrigation_frequency'] as String? ?? '';
    final List critOps = stage['critical_ops'] as List? ?? [];

    String status;
    if (isDone) {
      status = 'Completed';
    } else if (isCurrent) {
      status = daysLeft != null ? 'Current · $daysLeft days remaining' : 'Current';
    } else {
      status = 'Upcoming';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDone ? AppColors.primary : isCurrent ? Colors.white : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone || isCurrent ? AppColors.primary : AppColors.border,
                    width: isCurrent ? 5 : 2,
                  ),
                ),
                child: isDone ? const Icon(LucideIcons.check, color: Colors.white, size: 12) : null,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: critOps.isNotEmpty ? 80 : 56,
                  color: isDone ? AppColors.primary : AppColors.border,
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 16,
                          color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Day $dStart–$dEnd',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  Text(
                    status,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isCurrent ? AppColors.primary : AppColors.textMuted,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isCurrent && irrigFreq.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('💧 $irrigFreq',
                        style: AppTextStyles.caption.copyWith(color: AppColors.accentBlue)),
                  ],
                  if (isCurrent && critOps.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: (critOps.take(3)).map((op) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(op.toString(),
                            style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(String currentStage, Map<String, dynamic>? nextStage, int? daysLeft, bool sensitive) {
    String predText;
    if (nextStage != null && daysLeft != null) {
      final nextName = nextStage['name'] as String? ?? 'next stage';
      predText = 'Stage transition to $nextName expected in approximately $daysLeft days based on current DAP and soil moisture trends.';
    } else if (daysLeft != null) {
      predText = 'Crop is in $currentStage stage with approximately $daysLeft days remaining.';
    } else {
      predText = 'Crop is in $currentStage stage. Set sowing date to enable precise stage transition predictions.';
    }

    if (sensitive) {
      predText += ' ⚠️ This is a water-critical stage — maintain irrigation schedule closely.';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.accentPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: AppColors.accentPurple, size: 20),
              const SizedBox(width: 12),
              Text('AI STAGE PREDICTION',
                  style: AppTextStyles.label.copyWith(color: AppColors.accentPurple, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(predText,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark)),
        ],
      ),
    );
  }
}
