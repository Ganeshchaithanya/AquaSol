import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/animated_interactive_card.dart';

class CropPlannerScreen extends StatefulWidget {
  const CropPlannerScreen({super.key});

  @override
  State<CropPlannerScreen> createState() => _CropPlannerScreenState();
}

class _CropPlannerScreenState extends State<CropPlannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _plan;
  List<dynamic> _zones = [];
  String _selectedMode = 'existing_crop'; // 'existing_crop' or 'new_season'
  String? _selectedZoneId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    _zones = await apiService.getZones();
    
    if (_zones.isNotEmpty) {
      _selectedZoneId ??= _zones[0]['zone_id'].toString();
      final plan = await apiService.getCropPlan(
        query: _selectedMode == 'existing_crop' 
          ? 'How is my current crop doing and what should I do this week?' 
          : 'What should I grow in my next cycle for maximum profit?',
        zoneId: _selectedZoneId!,
        mode: _selectedMode,
      );
      setState(() {
        _plan = plan;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

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
            Text('Crop Planner', style: AppTextStyles.sectionLabel),
            Text('Smart Advisory · Lifecycle Guide', style: AppTextStyles.caption),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildModeSelector(),
          if (_zones.isNotEmpty) _buildZoneSelector(),
          Expanded(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTextStyles.label.copyWith(fontSize: 14),
                  tabs: const [
                    Tab(text: 'Recommendations'),
                    Tab(text: 'Cultivation Guide'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRecommendationsTab(),
                      _buildGuideTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildModeItem('Existing Crop', 'existing_crop'),
          _buildModeItem('New Season', 'new_season'),
        ],
      ),
    );
  }

  Widget _buildModeItem(String label, String mode) {
    bool isSel = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedMode = mode);
          _loadData();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSel 
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(
              color: isSel ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoneSelector() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _zones.length,
        itemBuilder: (context, index) {
          final zone = _zones[index];
          bool isSel = _selectedZoneId == zone['zone_id'].toString();
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: AnimatedInteractiveCard(
              onTap: () {
                setState(() => _selectedZoneId = zone['zone_id'].toString());
                _loadData();
              },
              isSelected: isSel,
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              selectedBackgroundColor: AppColors.primaryLight,
              child: Center(
                child: Text(
                  zone['name'],
                  style: AppTextStyles.caption.copyWith(
                    color: isSel ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    final crop = _plan?['recommended_crop'] ?? (_zones.isNotEmpty ? _zones.firstWhere((z) => z['zone_id'].toString() == _selectedZoneId, orElse: () => _zones[0])['crop_type'] : 'Unknown Crop');
    final agronomicJustification = _plan?['agronomic_justification'] ?? 'Analysing growth conditions...';
    final marketJustification = _plan?['market_justification'] ?? 'Fetching market data...';
    final riskFlags = (_plan?['risk_flags'] as List?)?.join(', ') ?? 'Monitoring environmental risks...';
    final ragSources = _plan?['rag_sources'] as List? ?? [];
    
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildPlanCard(crop),
        const SizedBox(height: 32),
        Text('STAGE RECOMMENDATIONS', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        _buildStageAdvisoryCard(
          stage: 'Current Focus',
          days: 'AI Analysis',
          recommendation: agronomicJustification,
          color: AppColors.accentGreen,
        ),
        const SizedBox(height: 32),
        Text('MARKET INSIGHTS', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        _buildAdvisoryItem(
          'Market Analysis',
          marketJustification,
          LucideIcons.trendingUp,
          AppColors.primary,
        ),
        _buildAdvisoryItem(
          'Risk Alert',
          riskFlags,
          LucideIcons.alertTriangle,
          AppColors.accentOrange,
        ),
        if (ragSources.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text('RAG KNOWLEDGE SOURCES', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          ...ragSources.map((source) => _buildAdvisoryItem(
            'ICAR Crop Guide',
            '${source['crop']} — ${source['step']}',
            LucideIcons.bookOpen,
            AppColors.accentBlue,
          )),
        ],
      ],
    );
  }

  Widget _buildStageAdvisoryCard({required String stage, required String days, required String recommendation, required Color color}) {
    return AnimatedInteractiveCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(stage, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Text(days, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 16),
          Text(recommendation, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: AppColors.accentPurple, size: 16),
              const SizedBox(width: 8),
              Text('AI-Generated Recommendation', style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String crop) {
    return AnimatedInteractiveCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      selectedBackgroundColor: Colors.transparent, // Uses gradient
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        padding: const EdgeInsets.all(24), // Keep inner padding for gradient container if needed, or remove
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_selectedMode == 'existing_crop' ? 'CURRENT CROP ANALYSIS' : 'NEXT CYCLE RECOMMENDATION', style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.3), letterSpacing: 1)),
            const SizedBox(height: 12),
            Text(crop, style: AppTextStyles.cardTitle.copyWith(color: Colors.white, fontSize: 24)),
            const SizedBox(height: 8),
            Text(_selectedMode == 'existing_crop' ? 'Optimizing Current Growth Stage' : 'High Profit Potential · Low Water Demand', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9))),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisoryItem(String title, String desc, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedInteractiveCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 24,
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
                  Text(title, style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(desc, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideTab() {
    final weeklyPlan = _plan?['weekly_plan'] as List? ?? [];

    if (weeklyPlan.isEmpty) {
      return const Center(child: Text('No cultivation guide available for this plan.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: weeklyPlan.length,
      itemBuilder: (context, index) {
        final week = weeklyPlan[index];
        final tasks = (week['tasks'] as List?)?.join(', ') ?? 'Preparation and monitoring';
        return _buildGuideStep('Week ${week['week']}', tasks, index < 2);
      },
    );
  }

  Widget _buildGuideStep(String title, String desc, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? LucideIcons.checkCircle2 : LucideIcons.circle,
            color: done ? AppColors.primary : AppColors.border,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: done ? AppColors.textSecondary : AppColors.textPrimary,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(desc, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
