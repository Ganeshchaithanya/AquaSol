import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class DeviceScannerScreen extends StatefulWidget {
  const DeviceScannerScreen({super.key});

  @override
  State<DeviceScannerScreen> createState() => _DeviceScannerScreenState();
}

class _DeviceScannerScreenState extends State<DeviceScannerScreen> {
  bool _isScanning = false;
  String? _selectedZoneId;
  String? _selectedNodeId;
  List<dynamic> _zones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final data = await apiService.getZones();
    if (mounted) {
      setState(() {
        _zones = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _onScan(String mac) async {
    if (_selectedZoneId == null || _selectedNodeId == null) return;
    
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    final result = await apiService.assignDevice(
      mac: mac,
      farmId: _zones.first['farm_id'], 
      zoneId: _selectedZoneId,
      nodeName: _selectedNodeId, // Use the label we are pairing for
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isScanning = false;
      });

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device paired successfully!'), backgroundColor: AppColors.accentGreen),
        );
        _loadZones(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pairing failed. Try again.'), backgroundColor: AppColors.accentRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return Scaffold(
        body: Stack(
          children: [
            MobileScanner(
              onDetect: (capture) {
                final barcode = capture.barcodes.first;
                if (barcode.rawValue != null) {
                  _onScan(barcode.rawValue!);
                }
              },
            ),
            Positioned(
              top: 40, left: 20,
              child: IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.white, size: 32),
                onPressed: () => setState(() => _isScanning = false),
              ),
            ),
            Center(
              child: Container(
                width: 250, height: 250,
                decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 4), borderRadius: BorderRadius.circular(24)),
              ),
            ),
            Positioned(
              bottom: 100, left: 0, right: 0,
              child: Column(
                children: [
                  Text('Scanning for $_selectedNodeId', style: AppTextStyles.label.copyWith(color: Colors.white)),
                  Text('Align the device QR code', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hardware Pairing'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _zones.length,
            itemBuilder: (context, index) {
              final zone = _zones[index];
              final List<dynamic> nodes = zone['nodes'] ?? [];
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(zone['name'] ?? 'Zone', style: AppTextStyles.sectionLabel.copyWith(color: AppColors.primary)),
                  ),
                  ...nodes.map((node) {
                    bool isPaired = node['mac_address'] != "PENDING" && node['mac_address'] != null;
                    bool isOnline = isPaired && (node['status'] == 'online' || node['status'] == 'active');
                    
                    Color itemBorderColor;
                    Color statusColor;
                    IconData statusIcon;
                    String statusText;
                    
                    if (!isPaired) {
                      itemBorderColor = AppColors.border;
                      statusColor = AppColors.textMuted;
                      statusIcon = LucideIcons.unplug;
                      statusText = 'Pairing Required';
                    } else if (isOnline) {
                      itemBorderColor = AppColors.accentGreen.withValues(alpha: 0.3);
                      statusColor = AppColors.accentGreen;
                      statusIcon = LucideIcons.checkCircle;
                      statusText = 'Connected';
                    } else {
                      itemBorderColor = AppColors.accentRed.withValues(alpha: 0.2);
                      statusColor = AppColors.accentRed;
                      statusIcon = LucideIcons.alertTriangle;
                      statusText = 'Offline';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: itemBorderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 20),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(node['node_label'] ?? 'Device', style: AppTextStyles.label),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isPaired ? 'ID: ${node['mac_address']}' : 'Pairing Required', 
                                        style: AppTextStyles.caption.copyWith(color: isPaired ? AppColors.textPrimary : AppColors.textMuted),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!isPaired)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedZoneId = zone['zone_id'];
                                  _selectedNodeId = node['node_label'];
                                  _isScanning = true;
                                });
                              },
                              icon: const Icon(LucideIcons.scan, size: 16),
                              label: const Text('Pair'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
    );
  }
}
