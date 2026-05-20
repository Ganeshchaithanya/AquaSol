import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';

class SystemHealthScreen extends StatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  State<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends State<SystemHealthScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _healthData;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getSystemHealth();
      if (mounted) {
        setState(() {
          _healthData = data;
        });
      }
    } catch (e) {
      debugPrint('Health load error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
            Text('System Health', style: AppTextStyles.sectionLabel),
            Text('Connected via AquaLink · Active', style: AppTextStyles.caption),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildHealthScoreCard(),
                    const SizedBox(height: 32),
                    Text('SENSOR STATUS', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    if (_healthData?['nodes'] != null)
                      ...(_healthData!['nodes'] as List).map((node) => _buildStatusItem(
                            node['label'] ?? 'Node',
                            (node['battery'] ?? 0) / 100.0,
                            node['status']?.toString().toUpperCase() ?? 'OFFLINE',
                          )),
                    const SizedBox(height: 32),
                    Text('WORKERS & NETWORK', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    _buildWorkerItem('AI Analysis Worker', '942 tasks', '145ms'),
                    _buildWorkerItem('Irrigation Controller', '${_healthData?['online_nodes'] ?? 0} active', '8ms'),
                    _buildWorkerItem('LoRa Network', _healthData?['gateway_status'] ?? 'Strong', '-92dBm'),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHealthScoreCard() {
    final score = _healthData?['score'] ?? 0;
    String status = score > 90 ? 'Optimal' : score > 70 ? 'Good' : 'Check Required';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.healthBlueGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentBlue.withValues(alpha: 0.2),
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
              Text('HEALTH SCORE', style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 16, letterSpacing: 1.5)),
              const Icon(LucideIcons.activity, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$score', style: AppTextStyles.dataDisplay.copyWith(color: Colors.white, fontSize: 64)),
              const SizedBox(width: 12),
              Text(status, style: AppTextStyles.label.copyWith(color: Colors.white.withValues(alpha: 0.8))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Current system integrity is $status. ${_healthData?['total_nodes'] ?? 0} nodes registered on network.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, double progress, String status) {
    Color color = status == 'ONLINE' ? AppColors.primary : AppColors.accentRed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
              Text(status, style: AppTextStyles.label.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerItem(String name, String value, String latency) {
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
          const Icon(LucideIcons.cpu, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: AppTextStyles.label)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppTextStyles.bodySmall),
              Text(latency, style: AppTextStyles.dataLabel.copyWith(fontSize: 10, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}
