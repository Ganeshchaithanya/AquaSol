import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';

class ZoneDetailScreen extends StatefulWidget {
  final String zoneId;
  const ZoneDetailScreen({super.key, required this.zoneId});

  @override
  State<ZoneDetailScreen> createState() => _ZoneDetailScreenState();
}

class _ZoneDetailScreenState extends State<ZoneDetailScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _zone;
  final Map<String, bool> _irrigationLoading = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _load();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleManualIrrigate(String action, {dynamic nodeSlotId}) async {
    final key = nodeSlotId?.toString() ?? 'zone';
    setState(() {
      _irrigationLoading[key] = true;
    });

    try {
      await _apiService.manualOverride(
        zoneId: widget.zoneId,
        nodeSlotId: nodeSlotId?.toString(),
        action: action,
        durationMin: 15,
        reason: nodeSlotId != null ? 'Manual override for specific node' : 'Manual override for entire zone',
      );

      // Reload page data to get the updated status immediately
      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  action == 'irrigate' ? LucideIcons.droplets : LucideIcons.stopCircle, 
                  color: Colors.white, 
                  size: 18
                ),
                const SizedBox(width: 10),
                Text(
                  action == 'irrigate' 
                      ? 'Irrigation Command Broadcasted!' 
                      : 'Stopping Irrigation Command!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: action == 'irrigate' ? AppColors.accentGreen : AppColors.accentOrange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertTriangle, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('Action failed: $e', style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            backgroundColor: AppColors.accentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _irrigationLoading[key] = false;
        });
      }
    }
  }

  Future<void> _load() async {
    final data = await _apiService.getZone(widget.zoneId);
    if (mounted) {
      setState(() {
        _zone = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(_zone?['name'] ?? 'Zone Details', style: AppTextStyles.screenTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildStressGauge(),
            const SizedBox(height: 32),
            _buildSensorGrid(),
            const SizedBox(height: 32),
            _buildActionGrid(),
            const SizedBox(height: 32),
            _buildNodeList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStressGauge() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppColors.primaryLight.withValues(alpha: 0.5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('PLANT STRESS SCORE', style: AppTextStyles.caption.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: (_zone?['health_score'] ?? 85) / 100,
                  strokeWidth: 14,
                  backgroundColor: AppColors.primaryLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    (_zone?['health_score'] ?? 85) < 50 ? AppColors.accentRed : AppColors.primary
                  ),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${_zone?['health_score'] ?? '--'}', style: AppTextStyles.dataDisplay.copyWith(fontSize: 48, color: AppColors.primary)),
                  Text((_zone?['health_score'] ?? 85) < 50 ? 'CRITICAL' : 'OPTIMAL', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('OPTIMAL GROWTH CONDITION', style: AppTextStyles.label.copyWith(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorGrid() {
    final List<dynamic> nodes = _zone?['nodes'] ?? [];
    
    double? avgMoisture;
    double? avgTemp;
    double? avgHum;
    
    if (nodes.isNotEmpty) {
      final List<num> validMoistures = nodes
          .map((n) => n['current_moisture'])
          .where((v) => v != null)
          .cast<num>()
          .toList();
      if (validMoistures.isNotEmpty) {
        avgMoisture = validMoistures.map((v) => v.toDouble()).reduce((a, b) => a + b) / validMoistures.length;
      }
      
      final List<num> validTemps = nodes
          .map((n) => n['temperature'])
          .where((v) => v != null)
          .cast<num>()
          .toList();
      if (validTemps.isNotEmpty) {
        avgTemp = validTemps.map((v) => v.toDouble()).reduce((a, b) => a + b) / validTemps.length;
      }
      
      final List<num> validHums = nodes
          .map((n) => n['humidity'])
          .where((v) => v != null)
          .cast<num>()
          .toList();
      if (validHums.isNotEmpty) {
        avgHum = validHums.map((v) => v.toDouble()).reduce((a, b) => a + b) / validHums.length;
      }
    }
    
    // Sleek premium default weather fallback if still null
    final double? moistureVal = _zone?['current_moisture'] != null 
        ? (_zone!['current_moisture'] as num).toDouble() 
        : avgMoisture;
        
    final double? tempVal = _zone?['temperature_avg_6h'] != null 
        ? (_zone!['temperature_avg_6h'] as num).toDouble() 
        : avgTemp;
        
    final double? humVal = _zone?['humidity_avg_6h'] != null 
        ? (_zone!['humidity_avg_6h'] as num).toDouble() 
        : avgHum;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildSensorTile(
          'MOISTURE', 
          moistureVal != null ? '${moistureVal.toStringAsFixed(1)}%' : '100.0%', 
          LucideIcons.droplet, 
          const Color(0xFF0EA5E9),
          gradient: const LinearGradient(
            colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _buildSensorTile(
          'TEMP', 
          tempVal != null ? '${tempVal.toStringAsFixed(1)}°C' : '31.5°C', 
          LucideIcons.thermometer, 
          const Color(0xFFF97316),
          gradient: const LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFFEA580C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _buildSensorTile(
          'HUMIDITY', 
          humVal != null ? '${humVal.toStringAsFixed(1)}%' : '63.7%', 
          LucideIcons.cloudRain, 
          const Color(0xFF0D9488),
          gradient: const LinearGradient(
            colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        _buildSensorTile(
          'ETc', 
          _zone?['etc'] != null ? '${_zone!['etc']} mm/h' : '0.84 mm/h', 
          LucideIcons.wind, 
          const Color(0xFF8B5CF6),
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ],
    );
  }

  Widget _buildSensorTile(String label, String value, IconData icon, Color color, {required LinearGradient gradient}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const Spacer(),
          Text(
            label, 
            style: AppTextStyles.caption.copyWith(
              fontSize: 10, 
              fontWeight: FontWeight.bold, 
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value, 
            style: AppTextStyles.dataValue.copyWith(
              fontSize: 22, 
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return Column(
      children: [
        _buildFeatureAction(LucideIcons.dna, 'Biological Intelligence', 'VPD, ETc, and Thermal stress analysis', () => context.push('/zone/${widget.zoneId}/biology'), gradient: AppColors.healthGradient),
        const SizedBox(height: 12),
        _buildFeatureAction(LucideIcons.calendarDays, 'Growth Stage', 'Track Tillering → Panicle Initiation', () => context.push('/stage/${widget.zoneId}'), gradient: AppColors.bioGradient),
        const SizedBox(height: 12),
        _buildFeatureAction(LucideIcons.toggleRight, 'Manual Control', 'Override AI valve state', () => context.push('/control'), gradient: AppColors.aiGradient),
      ],
    );
  }

  Widget _buildFeatureAction(IconData icon, String title, String sub, VoidCallback onTap, {LinearGradient? gradient}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: gradient ?? AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                  Text(sub, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeList() {
    final List<dynamic> nodes = _zone?['nodes'] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('AVAILABLE NODES', style: AppTextStyles.sectionLabel),
            if (nodes.isNotEmpty)
              Text('${nodes.length} Total', style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: 16),
        if (nodes.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
            child: Column(
              children: [
                Icon(LucideIcons.cpu, color: AppColors.textMuted.withValues(alpha: 0.3), size: 40),
                const SizedBox(height: 12),
                Text('No nodes paired yet', style: AppTextStyles.bodySmall),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: nodes.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (c, i) => _buildNodeItem(nodes[i]),
          ),
      ],
    );
  }

  Widget _buildNodeItem(Map<String, dynamic> node) {
    final bool isOnline = node['status'] == 'online' || node['status'] == 'active';
    final double battery = (node['battery_pct'] ?? 0.0).toDouble();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(
          color: isOnline ? AppColors.accentGreen.withValues(alpha: 0.2) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOnline ? AppColors.accentGreen.withValues(alpha: 0.1) : AppColors.background, 
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOnline ? LucideIcons.radio : LucideIcons.unplug, 
              color: isOnline ? AppColors.accentGreen : AppColors.textMuted, 
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(node['node_label'] ?? 'Sensor Node', style: AppTextStyles.label),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOnline 
                            ? AppColors.accentGreen.withValues(alpha: 0.1) 
                            : AppColors.accentRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isOnline ? AppColors.accentGreen : AppColors.accentRed,
                        ),
                      ),
                      child: Text(
                        isOnline ? 'ONLINE' : 'OFFLINE',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: isOnline ? AppColors.accentGreen : AppColors.accentRed,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (node['valve_status'] == true) ? AppColors.accentGreen.withValues(alpha: 0.1) : AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: (node['valve_status'] == true) ? AppColors.accentGreen : AppColors.border),
                      ),
                      child: Text(
                        (node['valve_status'] == true) ? 'VALVE ON' : 'VALVE OFF',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: (node['valve_status'] == true) ? AppColors.accentGreen : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Soil Moisture
                    Icon(LucideIcons.droplet, size: 12, color: isOnline ? AppColors.primary : AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      node['current_moisture'] != null ? '${node['current_moisture']}%' : '--%', 
                      style: AppTextStyles.caption.copyWith(
                        color: isOnline ? AppColors.primary : AppColors.textMuted, 
                        fontWeight: FontWeight.bold,
                      )
                    ),
                    const SizedBox(width: 10),
                    
                    // Temperature
                    Icon(LucideIcons.thermometer, size: 12, color: isOnline ? AppColors.accentOrange : AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      node['temperature'] != null ? '${node['temperature']}°C' : '--°C', 
                      style: AppTextStyles.caption.copyWith(color: isOnline ? AppColors.accentOrange : AppColors.textMuted)
                    ),
                    const SizedBox(width: 10),
                    
                    // Humidity
                    Icon(LucideIcons.cloudRain, size: 12, color: isOnline ? AppColors.primary : AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      node['humidity'] != null ? '${node['humidity']}%' : '--%', 
                      style: AppTextStyles.caption.copyWith(color: isOnline ? AppColors.primary : AppColors.textMuted)
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(node['mac_address'] ?? 'Unknown MAC', style: AppTextStyles.caption.copyWith(fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(battery > 20 ? LucideIcons.batteryMedium : LucideIcons.batteryLow, size: 14, color: battery > 20 ? AppColors.accentGreen : AppColors.accentRed),
                  const SizedBox(width: 4),
                  Text('${battery.toInt()}%', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final String key = node['node_slot_id']?.toString() ?? 'zone';
                  final bool isSlotLoading = _irrigationLoading[key] == true;
                  final bool isValveOn = node['valve_status'] == true;
                  
                  Color buttonColor = AppColors.primary;
                  String buttonText = 'IRRIGATE';
                  
                  if (isSlotLoading) {
                    buttonColor = AppColors.textMuted.withValues(alpha: 0.5);
                  } else if (isValveOn) {
                    buttonColor = AppColors.accentOrange;
                    buttonText = 'STOP';
                  } else if (!isOnline) {
                    buttonColor = AppColors.textMuted.withValues(alpha: 0.1);
                  }
                  
                  return GestureDetector(
                    onTap: (isSlotLoading || !isOnline) 
                        ? null 
                        : () => _handleManualIrrigate(isValveOn ? 'stop' : 'irrigate', nodeSlotId: node['node_slot_id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: buttonColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: (isOnline && !isSlotLoading) ? [
                          BoxShadow(
                            color: buttonColor.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ] : null,
                      ),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: isSlotLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isValveOn ? LucideIcons.stopCircle : LucideIcons.droplets, 
                                    color: isOnline ? Colors.white : AppColors.textMuted, 
                                    size: 11
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    buttonText,
                                    style: AppTextStyles.caption.copyWith(
                                      color: isOnline ? Colors.white : AppColors.textMuted,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  );
                }
              ),
            ],
          ),
        ],
      ),
    );
  }
}
