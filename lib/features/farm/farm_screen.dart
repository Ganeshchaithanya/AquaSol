import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';
import 'package:aquasol_app/shared/widgets/animated_interactive_card.dart';

class FarmScreen extends StatefulWidget {
  const FarmScreen({super.key});

  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _acres = [];
  List<dynamic> _zones = []; // For the currently selected acre
  Map<String, dynamic>? _selectedAcre;
  Map<String, dynamic>? _masterStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final dashboard = await _apiService.getDashboard();
      if (mounted && dashboard != null) {
        setState(() {
          _acres = dashboard['acres'] ?? [];
          _masterStatus = dashboard['master_status'];
          // If we were already looking at an acre, refresh its data
          if (_selectedAcre != null) {
            _selectedAcre = _acres.firstWhere(
              (a) => a['acre_id'] == _selectedAcre!['acre_id'],
              orElse: () => null,
            );
            _zones = _selectedAcre?['zones'] ?? [];
          }
        });
      }
    } catch (e) {
      debugPrint('Farm load error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _acres.isEmpty) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: _selectedAcre != null 
          ? IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: AppColors.primary),
              onPressed: () => setState(() {
                _selectedAcre = null;
                _zones = [];
              }),
            )
          : null,
        title: _selectedAcre != null 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(LucideIcons.chevronLeft, size: 16, color: AppColors.textSecondary),
                  onPressed: () {
                    final idx = _acres.indexWhere((a) => a['acre_id'] == _selectedAcre!['acre_id']);
                    if (idx > 0) {
                      setState(() {
                        _selectedAcre = _acres[idx - 1];
                        _zones = _selectedAcre!['zones'] ?? [];
                      });
                    }
                  },
                ),
                Text(_selectedAcre?['name'] ?? 'Acre', style: AppTextStyles.screenTitle),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSecondary),
                  onPressed: () {
                    final idx = _acres.indexWhere((a) => a['acre_id'] == _selectedAcre!['acre_id']);
                    if (idx < _acres.length - 1) {
                      setState(() {
                        _selectedAcre = _acres[idx + 1];
                        _zones = _selectedAcre!['zones'] ?? [];
                      });
                    }
                  },
                ),
              ],
            )
          : Text('My Farm', style: AppTextStyles.screenTitle),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              if (_selectedAcre == null) ...[
                _buildMasterCard(),
                const SizedBox(height: 32),
                Text('Select an Acre', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 16),
                _buildAcreGrid(),
              ] else ...[
                _buildVisualMap(),
                const SizedBox(height: 32),
                Text('Zones in ${_selectedAcre!['name']}', style: AppTextStyles.sectionLabel),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _zones.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 16),
                  itemBuilder: (c, i) => _buildZoneCard(_zones[i]),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcreGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: _acres.length,
      itemBuilder: (context, index) {
        final acre = _acres[index];
        return AnimatedInteractiveCard(
          onTap: () => setState(() {
            _selectedAcre = acre;
            _zones = acre['zones'] ?? [];
          }),
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: index % 2 == 0 ? AppColors.healthGradient : AppColors.waterGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.map, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Text(acre['name'] ?? 'Acre', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${acre['total_zones']} Zones', style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVisualMap() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(12),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        physics: const NeverScrollableScrollPhysics(),
        children: _zones.take(4).map((z) => _buildMapZone(z)).toList(),
      ),
    );
  }

  Widget _buildMapZone(Map<String, dynamic> zone) {
    final moisture = zone['current_moisture'];
    final List<dynamic> zoneNodes = zone['nodes'] ?? [];
    final bool hasAssignedNodes = zoneNodes.any((n) =>
        n['mac_address'] != null && n['mac_address'] != 'PENDING');
    final isPending = !hasAssignedNodes;
    final bool isOffline = !isPending && !zoneNodes.any((n) =>
        n['mac_address'] != null && 
        n['mac_address'] != 'PENDING' && 
        (n['status'] == 'online' || n['status'] == 'active'));
    final isDry = !isPending && !isOffline && moisture != null && moisture < 50;
    
    return Container(
      decoration: BoxDecoration(
        color: isPending 
            ? AppColors.textPrimary.withValues(alpha: 0.05)
            : (isOffline 
                ? AppColors.textPrimary.withValues(alpha: 0.02)
                : (isDry ? AppColors.accentOrange.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1))),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? AppColors.border
              : (isOffline
                  ? AppColors.border.withValues(alpha: 0.5)
                  : (isDry ? AppColors.accentOrange.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.3))),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCropIcon(zone['crop_type']),
              color: isPending 
                  ? AppColors.textSecondary 
                  : (isOffline 
                      ? AppColors.textMuted 
                      : (isDry ? AppColors.accentOrange : AppColors.primary)),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              zone['name'] ?? '?',
              style: AppTextStyles.sectionLabel.copyWith(
                color: isPending 
                    ? AppColors.textSecondary 
                    : (isOffline 
                        ? AppColors.textMuted 
                        : (isDry ? AppColors.accentOrange : AppColors.primary)),
                fontSize: 14,
              ),
            ),
            Text(
              isPending 
                  ? 'Pending' 
                  : (isOffline ? 'Offline' : '$moisture%'), 
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneCard(Map<String, dynamic> zone) {
    final mode = zone['operating_mode'] ?? 'OPTIMAL_RANGE';
    final moisture = zone['current_moisture'];
    final List<dynamic> nodes = zone['nodes'] ?? [];
    final bool hasAssignedNodes = nodes.any((n) =>
        n['mac_address'] != null && n['mac_address'] != 'PENDING');
    final isPending = !hasAssignedNodes;
    final bool isOffline = !isPending && !nodes.any((n) =>
        n['mac_address'] != null && 
        n['mac_address'] != 'PENDING' && 
        (n['status'] == 'online' || n['status'] == 'active'));
    
    final isHeatStress = mode == 'HEAT_STRESS';
    final isValveOn = zone['valve_state'] == true;
    final bool isVirtual = zone['virtual_sensing_active'] == true;
    
    // Premium color palettes and gradients per state
    LinearGradient cardGradient;
    Color borderAccent;
    Color primaryColor;
    
    if (isPending) {
      cardGradient = const LinearGradient(
        colors: [Colors.white, Color(0xFFF8FAFC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderAccent = AppColors.textMuted.withValues(alpha: 0.1);
      primaryColor = AppColors.textMuted;
    } else if (isOffline) {
      cardGradient = LinearGradient(
        colors: [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0).withValues(alpha: 0.8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderAccent = AppColors.accentRed.withValues(alpha: 0.15);
      primaryColor = AppColors.textSecondary;
    } else if (isValveOn) {
      cardGradient = const LinearGradient(
        colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderAccent = AppColors.accentGreen.withValues(alpha: 0.4);
      primaryColor = AppColors.primary;
    } else if (isHeatStress) {
      cardGradient = const LinearGradient(
        colors: [Color(0xFFFFF7ED), Color(0xFFFFE4E6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderAccent = AppColors.accentOrange.withValues(alpha: 0.4);
      primaryColor = AppColors.accentOrange;
    } else {
      cardGradient = LinearGradient(
        colors: [Colors.white, const Color(0xFFF0FDF4).withValues(alpha: 0.4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderAccent = AppColors.primary.withValues(alpha: 0.15);
      primaryColor = AppColors.primary;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => GoRouter.of(context).push('/farm/zone/${zone['zone_id']}', extra: {'name': zone['name']}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: cardGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderAccent, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.04), 
              blurRadius: 20, 
              offset: const Offset(0, 8)
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor.withValues(alpha: 0.2), primaryColor.withValues(alpha: 0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_getCropIcon(zone['crop_type']), color: primaryColor, size: 28),
                    ),
                    if (isValveOn)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: AppColors.accentGreen.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zone['name'] ?? 'Zone', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(zone['crop_type'] ?? 'Unknown', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                          if (zone['current_stage'] != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                zone['current_stage'].toString().toUpperCase(),
                                style: AppTextStyles.caption.copyWith(fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          if (isVirtual) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accentPurple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'VIRTUAL',
                                style: AppTextStyles.caption.copyWith(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.accentPurple),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isPending 
                          ? '--%' 
                          : (isOffline ? 'OFFLINE' : '${moisture ?? 0}%'), 
                      style: AppTextStyles.dataValue.copyWith(
                        fontSize: isOffline ? 15 : 22, 
                        color: isOffline ? AppColors.textMuted : primaryColor,
                        fontWeight: FontWeight.bold,
                      )
                    ),
                    _buildModeBadge(isPending ? 'PENDING' : mode, isOffline: isOffline),
                  ],
                ),
              ],
            ),
            
            // Dynamic Target Soil Moisture Progress Bar
            if (!isPending && !isOffline && moisture != null) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      // Base track
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      // Target range highlight
                      Positioned(
                        left: MediaQuery.of(context).size.width * 0.45 * ((zone['target_moisture_min'] ?? 20.0) / 100.0),
                        right: MediaQuery.of(context).size.width * 0.45 * (1.0 - ((zone['target_moisture_max'] ?? 80.0) / 100.0)),
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.accentBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      // Current value indicator fill
                      FractionallySizedBox(
                        widthFactor: (moisture.toDouble() / 100.0).clamp(0.0, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, primaryColor.withValues(alpha: 0.6)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 1))
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Target Min: ${(zone['target_moisture_min'] ?? 20.0).toInt()}%', style: AppTextStyles.caption.copyWith(fontSize: 9, color: AppColors.textSecondary)),
                      Text('Current: ${moisture.toInt()}%', style: AppTextStyles.caption.copyWith(fontSize: 9, fontWeight: FontWeight.bold, color: primaryColor)),
                      Text('Target Max: ${(zone['target_moisture_max'] ?? 80.0).toInt()}%', style: AppTextStyles.caption.copyWith(fontSize: 9, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeBadge(String mode, {bool isOffline = false}) {
    final isOptimal = mode == 'OPTIMAL_RANGE';
    final isPending = mode == 'PENDING';
    
    Color bgColor;
    Color textColor;
    String label;
    
    if (isPending) {
      bgColor = AppColors.textPrimary.withValues(alpha: 0.1);
      textColor = AppColors.textSecondary;
      label = 'Pending Pairing';
    } else if (isOffline) {
      bgColor = AppColors.textPrimary.withValues(alpha: 0.05);
      textColor = AppColors.textMuted;
      label = 'Disconnected';
    } else {
      bgColor = isOptimal ? AppColors.accentGreen.withValues(alpha: 0.1) : AppColors.accentRed.withValues(alpha: 0.1);
      textColor = isOptimal ? AppColors.accentGreen : AppColors.accentRed;
      label = isOptimal ? 'Optimal' : 'Heat Stress';
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getCropIcon(String? cropType) {
    switch (cropType?.toLowerCase()) {
      case 'rice': return LucideIcons.wheat;
      case 'tomato': return LucideIcons.apple;
      case 'mango': return LucideIcons.citrus;
      case 'grape': return LucideIcons.grape;
      case 'banana': return LucideIcons.citrus;
      case 'coffee': return LucideIcons.coffee;
      default: return LucideIcons.sprout;
    }
  }

  Widget _buildMasterCard() {
    if (_masterStatus == null) return const SizedBox.shrink();
    
    final bool isOnline = _masterStatus!['status'] == 'active' || _masterStatus!['status'] == 'online';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // Modern Slate/Navy
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isOnline ? AppColors.accentGreen : AppColors.accentRed).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (isOnline ? AppColors.accentGreen : AppColors.accentRed).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? AppColors.accentGreen : AppColors.accentRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: (isOnline ? AppColors.accentGreen : AppColors.accentRed).withValues(alpha: 0.5), blurRadius: 6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnline ? 'GATEWAY ONLINE' : 'GATEWAY OFFLINE',
                      style: AppTextStyles.caption.copyWith(color: isOnline ? AppColors.accentGreen : AppColors.accentRed, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(LucideIcons.radio, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Text('MASTER GATEWAY', style: AppTextStyles.label.copyWith(color: Colors.white, letterSpacing: 1.5, fontSize: 12)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMasterStat(
                  LucideIcons.droplets, 
                  'Flow', 
                  '${_masterStatus?['flow_rate'] ?? 0.0} L/m',
                  AppColors.accentBlue
                ),
                _buildMasterStat(
                  LucideIcons.cloudRain, 
                  'Rain', 
                  _masterStatus?['rain_detected'] == true ? 'YES' : 'NO',
                  AppColors.accentOrange
                ),
                _buildMasterStat(
                  LucideIcons.sun, 
                  'Solar', 
                  '${_masterStatus?['solar_voltage'] ?? 0.0}V',
                  AppColors.accentGold
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterStat(IconData icon, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
      ],
    );
  }
}
