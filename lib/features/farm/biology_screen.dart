import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';

class BiologyScreen extends StatefulWidget {
  final String zoneId;
  const BiologyScreen({super.key, required this.zoneId});

  @override
  State<BiologyScreen> createState() => _BiologyScreenState();
}

class _BiologyScreenState extends State<BiologyScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _bioData;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getBiology(widget.zoneId);
      if (mounted) setState(() => _bioData = data);
    } catch (e) {
      debugPrint('Biology load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final d = _bioData ?? {};
    final cropType = (d['crop_type'] as String? ?? 'Unknown').toUpperCase();
    final growthStage = d['growth_stage'] as String? ?? 'Unknown';
    final season = (d['season'] as String? ?? '').toUpperCase();
    final dap = d['dap'] as int? ?? 0;
    final etc = (d['etc_rate'] as num?)?.toDouble() ?? 0.0;
    final vpd = (d['vpd'] as num?)?.toDouble() ?? 0.0;
    final kc = (d['kc'] as num?)?.toDouble() ?? 0.0;
    final tsi = (d['tsi'] as num?)?.toDouble() ?? 0.0;
    final bioScore = (d['bio_score'] as num?)?.toInt() ?? (100 - tsi.toInt()).clamp(0, 100);
    final moistureNow = (d['moisture_now'] as num?)?.toDouble() ?? 0.0;
    final moistureMin = (d['moisture_target_min'] as num?)?.toDouble() ?? 50.0;
    final moistureMax = (d['moisture_target_max'] as num?)?.toDouble() ?? 70.0;
    final stageSensitive = d['stage_sensitive'] as bool? ?? false;
    final growthPct = (d['growth_progress_pct'] as num?)?.toDouble() ?? 0.0;
    final irrigFreq = d['irrigation_frequency'] as String? ?? 'As needed';
    final aiRec = d['ai_recommendation'] as String?;

    final recoveryPlan = (d['recovery_plan'] as List<dynamic>?) ?? [];

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
            Text('Biological Intelligence', style: AppTextStyles.sectionLabel),
            Text('$cropType · $growthStage · DAP $dap', style: AppTextStyles.caption),
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
              _buildBioScoreCard(bioScore, cropType, growthStage, dap, stageSensitive, growthPct),
              const SizedBox(height: 20),
              if (aiRec != null) _buildAICard(aiRec),
              const SizedBox(height: 32),
              Text('PLANT PARAMETERS', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              _buildParameterItem('Moisture Now', moistureNow / 100.0, '${moistureNow.toStringAsFixed(1)}%',
                  subtitle: 'Target: ${moistureMin.toStringAsFixed(0)}–${moistureMax.toStringAsFixed(0)}%'),
              _buildParameterItem('ETc (Evapotranspiration)', (etc / 10.0).clamp(0, 1), '${etc.toStringAsFixed(2)} mm/day'),
              _buildParameterItem('VPD (Vapour Pressure Deficit)', (vpd / 3.0).clamp(0, 1), '${vpd.toStringAsFixed(2)} kPa'),
              _buildParameterItem('Kc (Crop Coefficient)', (kc / 1.5).clamp(0, 1), kc.toStringAsFixed(3)),
              _buildParameterItem('TSI (Thermal Stress Index)', (tsi / 100.0).clamp(0, 1), '${tsi.toStringAsFixed(1)} / 100'),
              const SizedBox(height: 8),
              _buildInfoRow('Irrigation Frequency', irrigFreq, LucideIcons.droplets),
              _buildInfoRow('Season', season, LucideIcons.sun),
              const SizedBox(height: 32),
              _buildRecoveryPlanHeader(bioScore),
              const SizedBox(height: 16),
              if (recoveryPlan.isEmpty)
                _buildChecklistItem('No recovery needed — crop is healthy', true, 'Optimal')
              else
                ...recoveryPlan.map((item) {
                  final task = item['task'] as String? ?? '';
                  final day = item['day'] as String? ?? '';
                  final done = item['done'] as bool? ?? false;
                  return _buildChecklistItem(task, done, day);
                }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBioScoreCard(int score, String crop, String stage, int dap, bool sensitive, double progress) {
    String status = score > 80 ? 'STRONG' : score > 50 ? 'MODERATE' : 'STRESSED';
    String description = score > 80
        ? 'High photosynthetic efficiency. $crop is in optimal condition at $stage stage (DAP $dap).'
        : score > 50
            ? '$crop shows moderate performance in $stage stage. Monitor moisture closely.'
            : 'Stress detected in $crop at $stage stage. Immediate action recommended.${sensitive ? " ⚠️ Water-critical stage!" : ""}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.bioGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withValues(alpha: 0.2),
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
                  Text(status, style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 14, letterSpacing: 1.5)),
                  Text(crop, style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.7))),
                ],
              ),
              if (sensitive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('⚠️ Critical Stage', style: AppTextStyles.caption.copyWith(color: Colors.white)),
                )
              else
                const Icon(LucideIcons.leaf, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$score', style: AppTextStyles.dataDisplay.copyWith(color: Colors.white, fontSize: 64)),
              const SizedBox(width: 8),
              Text('Bio score', style: AppTextStyles.label.copyWith(color: Colors.white.withValues(alpha: 0.8))),
            ],
          ),
          const SizedBox(height: 8),
          // Crop cycle progress bar
          Row(
            children: [
              Text('Cycle Progress', style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.7))),
              const Spacer(),
              Text('${progress.toStringAsFixed(1)}%', style: AppTextStyles.caption.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(description, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9))),
        ],
      ),
    );
  }

  Widget _buildAICard(String rec) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentPurple.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.sparkles, color: AppColors.accentPurple, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(rec, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterItem(String label, double progress, String value, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                  if (subtitle != null)
                    Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                ],
              ),
              Text(value, style: AppTextStyles.label.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildRecoveryPlanHeader(int score) {
    final label = score > 80 ? 'MAINTENANCE PLAN' : 'RECOVERY PLAN';
    final tagLabel = score > 80 ? 'Healthy' : 'Active';
    final tagColor = score > 80 ? AppColors.accentGreen : AppColors.accentGold;
    return Row(
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(tagLabel, style: AppTextStyles.caption.copyWith(color: tagColor, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(String title, bool completed, String tag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            completed ? LucideIcons.checkCircle2 : LucideIcons.circle,
            color: completed ? AppColors.accentGreen : AppColors.textMuted,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.label.copyWith(
                color: completed ? AppColors.textSecondary : AppColors.textPrimary,
                decoration: completed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tag == 'Today'
                  ? AppColors.accentBlue.withValues(alpha: 0.1)
                  : tag == 'Ongoing'
                      ? AppColors.accentGreen.withValues(alpha: 0.1)
                      : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: AppTextStyles.caption.copyWith(
                color: tag == 'Today'
                    ? AppColors.accentBlue
                    : tag == 'Ongoing'
                        ? AppColors.accentGreen
                        : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
