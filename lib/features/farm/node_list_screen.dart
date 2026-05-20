import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';
import 'package:provider/provider.dart';

class NodeListScreen extends StatefulWidget {
  final String zoneId;
  final String zoneName;

  const NodeListScreen({
    super.key,
    required this.zoneId,
    required this.zoneName,
  });

  @override
  State<NodeListScreen> createState() => _NodeListScreenState();
}

class _NodeListScreenState extends State<NodeListScreen> {
  bool _isLoading = true;
  List<dynamic> _nodes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final zoneData = await apiService.getZone(widget.zoneId);
      if (mounted && zoneData != null) {
        setState(() {
          _nodes = zoneData['nodes'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Load nodes error: $e');
    } finally {
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
        title: Text(widget.zoneName, style: AppTextStyles.label.copyWith(fontSize: 18)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _nodes.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _nodes.length,
                  itemBuilder: (context, index) {
                    final node = _nodes[index];
                    return _buildNodeCard(node);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.cpu, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No nodes assigned to this zone', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildNodeCard(Map<String, dynamic> node) {
    final bool isOnline = node['status'] == 'online' || node['status'] == 'active';
    final String label = node['node_label'] ?? 'Sensor Node';
    final String mac = node['mac_address'] ?? 'Unknown';
    final double battery = (node['battery_pct'] ?? 0.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isOnline ? AppColors.accentGreen.withValues(alpha: 0.1) : AppColors.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(LucideIcons.radio, color: isOnline ? AppColors.accentGreen : AppColors.textMuted),
        ),
        title: Text(label, style: AppTextStyles.label),
        subtitle: Text(mac, style: AppTextStyles.caption),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  battery > 20 ? LucideIcons.batteryMedium : LucideIcons.batteryLow,
                  size: 14,
                  color: battery > 20 ? AppColors.accentGreen : AppColors.accentRed,
                ),
                const SizedBox(width: 4),
                Text('${battery.toInt()}%', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isOnline ? 'ONLINE' : 'OFFLINE',
              style: AppTextStyles.caption.copyWith(
                color: isOnline ? AppColors.accentGreen : AppColors.accentRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () {
          // Navigate to Node Detail
          context.push('/farm/node/${node['mac_address']}', extra: node);
        },
      ),
    );
  }
}
