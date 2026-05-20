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
      if (mounted) {
        setState(() {
          _bioData = data;
        });
      }
    } catch (e) {
      debugPrint('Biology load error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final etc = _bioData?['etc_rate'] ?? 0.0;
    final vpd = _bioData?['vpd'] ?? 0.0;
    final kc = _bioData?['kc'] ?? 0.0;
    final growthStage = _bioData?['growth_stage'] ?? 'Vegetative';

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
            Text('Zone ${widget.zoneId} · $growthStage Stage', style: AppTextStyles.caption),
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
              _buildBioScoreCard(),
              const SizedBox(height: 32),
              Text('PLANT PARAMETERS', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              _buildParameterItem('ETc (Evapotranspiration)', etc / 10.0, '$etc mm/day'),
              _buildParameterItem('VPD (Pressure Deficit)', vpd / 3.0, '$vpd kPa'),
              _buildParameterItem('Kc (Crop Coefficient)', kc / 1.5, '$kc'),
              _buildParameterItem('TSI (Thermal Stress)', (_bioData?['tsi'] ?? 0.0) / 100.0, '${_bioData?['tsi'] ?? 0.0}'),
              const SizedBox(height: 32),
              _buildRecoveryPlanHeader(),
              const SizedBox(height: 16),
              _buildChecklistItem('Soil Flushing (Day 1)', true, 'Today'),
              _buildChecklistItem('Nitrogen Supplement', false, 'Day 2'),
              _buildChecklistItem('Phosphate Dose', false, 'Day 4'),
              _buildChecklistItem('Deep Irrigation', false, 'Day 6'),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBioScoreCard() {
    final tsi = _bioData?['tsi'] ?? 0.0;
    final score = (100 - tsi).toInt().clamp(0, 100);
    String status = score > 80 ? 'STRONG' : score > 50 ? 'AVERAGE' : 'WEAK';

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
              Text(status, style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 16, letterSpacing: 1.5)),
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
          Text(
            score > 80 
              ? 'High photosynthetic efficiency detected. Optimal nutrient uptake in progress.'
              : 'Plant stress detected. Recommendation: adjust irrigation frequency.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterItem(String label, double progress, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
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

  Widget _buildRecoveryPlanHeader() {
    return Row(
      children: [
        Text('RECOVERY PLAN · 7 DAYS', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accentGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Active', style: AppTextStyles.caption.copyWith(color: AppColors.accentGold, fontWeight: FontWeight.bold)),
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
              color: tag == 'Today' ? AppColors.accentBlue.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: AppTextStyles.caption.copyWith(
                color: tag == 'Today' ? AppColors.accentBlue : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
