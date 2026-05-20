import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/animated_interactive_card.dart';
import '../../core/services/api_service.dart';

class NodeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> initialNode;
  final String? zoneId;

  const NodeDetailScreen({
    super.key,
    required this.initialNode,
    this.zoneId,
  });

  @override
  State<NodeDetailScreen> createState() => _NodeDetailScreenState();
}

class _NodeDetailScreenState extends State<NodeDetailScreen> {
  late Map<String, dynamic> _node;
  Timer? _refreshTimer;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _node = widget.initialNode;
    if (widget.zoneId != null) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        _refreshTelemetry();
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshTelemetry() async {
    if (widget.zoneId == null) return;
    try {
      final zoneData = await _apiService.getZone(widget.zoneId!);
      if (mounted && zoneData != null) {
        final nodes = zoneData['nodes'] as List<dynamic>? ?? [];
        final updatedNode = nodes.firstWhere(
          (n) => n['mac_address'] == widget.initialNode['mac_address'],
          orElse: () => null,
        );
        if (updatedNode != null) {
          setState(() {
            _node = updatedNode;
          });
        }
      }
    } catch (e) {
      debugPrint('Error refreshing node telemetry: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String label = _node['node_label'] ?? 'Sensor Node';
    final String mac = _node['mac_address'] ?? 'Unknown';
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(label, style: AppTextStyles.label.copyWith(fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(label, mac),
            const SizedBox(height: 32),
            Text('Live Telemetry', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 16),
            _buildTelemetryGrid(),
            const SizedBox(height: 32),
            _buildStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String label, String mac) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(LucideIcons.radio, color: AppColors.primary, size: 40),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
              Text('MAC: $mac', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildDataCard('Soil Moisture', '${_node['current_moisture'] ?? "--"}%', LucideIcons.droplet, AppColors.accentBlue),
        _buildDataCard('Temperature', '${_node['temperature'] ?? "--"}°C', LucideIcons.thermometer, AppColors.accentOrange),
        _buildDataCard('Humidity', '${_node['humidity'] ?? "--"}%', LucideIcons.wind, AppColors.accentBlue),
        _buildDataCard('Battery', '${_node['battery_pct'] ?? "--"}%', LucideIcons.battery, AppColors.accentGreen),
      ],
    );
  }

  Widget _buildDataCard(String label, String value, IconData icon, Color color) {
    return AnimatedInteractiveCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Text(value, style: AppTextStyles.dataValue.copyWith(fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final bool valveOn = _node['valve_status'] == true || _node['valve_status'] == 1;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Valve Status', style: AppTextStyles.label),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: valveOn ? AppColors.accentGreen.withValues(alpha: 0.1) : AppColors.textPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  valveOn ? 'OPEN' : 'CLOSED',
                  style: AppTextStyles.caption.copyWith(
                    color: valveOn ? AppColors.accentGreen : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Last Signal', style: AppTextStyles.label),
              Text(_node['last_seen'] ?? 'Recently', style: AppTextStyles.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}
