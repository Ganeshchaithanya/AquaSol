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
      if (mounted) {
        setState(() {
          _stageData = bio;
        });
      }
    } catch (e) {
      debugPrint('Stage load error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final currentStage = _stageData?['growth_stage'] ?? 'Vegetative';
    final stageNum = currentStage == 'Vegetative' ? 2 : currentStage == 'Flowering' ? 3 : 1;

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
            Text('Zone ${widget.zoneId} · Dynamic Monitoring', style: AppTextStyles.caption),
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
              _buildStageHeader(currentStage, stageNum),
              const SizedBox(height: 32),
              Text('GROWTH TIMELINE', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 24),
              _buildTimeline(currentStage),
              const SizedBox(height: 32),
              _buildPredictionCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageHeader(String stage, int num) {
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
              Text(stage.toUpperCase(), style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 16, letterSpacing: 2)),
              const Icon(LucideIcons.flower2, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Stage $num', style: AppTextStyles.dataDisplay.copyWith(color: Colors.white, fontSize: 48)),
              const SizedBox(width: 12),
              Text('of 5', style: AppTextStyles.label.copyWith(color: Colors.white.withValues(alpha: 0.6))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Biological indicators show $stage stage activity. Resource management optimized for this period.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(String current) {
    final stages = [
      {'name': 'Establishment', 'status': 'Completed', 'date': 'Week 1', 'isDone': true, 'isCurrent': false},
      {'name': 'Vegetative', 'status': current == 'Vegetative' ? 'Current' : 'Completed', 'date': 'Week 4', 'isDone': current != 'Vegetative', 'isCurrent': current == 'Vegetative'},
      {'name': 'Flowering', 'status': current == 'Flowering' ? 'Current' : 'Upcoming', 'date': 'Week 8', 'isDone': false, 'isCurrent': current == 'Flowering'},
      {'name': 'Fruit Set', 'status': 'Upcoming', 'date': 'Week 12', 'isDone': false, 'isCurrent': false},
      {'name': 'Ripening', 'status': 'Upcoming', 'date': 'Week 16', 'isDone': false, 'isCurrent': false},
    ];

    return Column(
      children: stages.asMap().entries.map((e) => _buildTimelineItem(e.value, e.key == stages.length - 1)).toList(),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> stage, bool isLast) {
    bool isDone = stage['isDone'];
    bool isCurrent = stage['isCurrent'];

    return Row(
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
                  width: isCurrent ? 6 : 2,
                ),
              ),
              child: isDone ? const Icon(LucideIcons.check, color: Colors.white, size: 12) : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: isDone ? AppColors.primary : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stage['name'],
                    style: AppTextStyles.label.copyWith(
                      fontSize: 18,
                      color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(stage['date'], style: AppTextStyles.bodySmall),
                ],
              ),
              Text(
                stage['status'],
                style: AppTextStyles.bodySmall.copyWith(
                  color: isCurrent ? AppColors.primary : AppColors.textMuted,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionCard() {
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
              Text('AI PREDICTION', style: AppTextStyles.label.copyWith(color: AppColors.accentPurple, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Stage transition expected in approximately 14 days based on current VPD and ETc rates.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}
