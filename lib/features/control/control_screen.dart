import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import './scheduling_screen.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final _apiService = ApiService();
  bool _isAutoMode = true;
  List<dynamic> _zones = [];
  bool _isLoading = true;
  String? _selectedZoneId;
  Map<String, dynamic>? _waterUsage;
  final Map<String, bool> _irrigationLoading = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getZones();
      _waterUsage = await _apiService.getWaterUsage();
      if (mounted) {
        setState(() {
          _zones = data;
          if (_zones.isNotEmpty) {
            _selectedZoneId ??= _zones[0]['zone_id'].toString();
          }
        });
      }
    } catch (e) {
      debugPrint('Control load error: $e');
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildModeToggle(),
                            if (!_isAutoMode) _buildManualAlert(),
                            const SizedBox(height: 24),
                            _buildWaterBudgetCard(),
                            const SizedBox(height: 32),
                            Text(
                              'ZONES',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._zones.map((z) => _buildZoneCard(z)),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Control Center', style: AppTextStyles.screenTitle),
          InteractiveScaleButton(
            onTap: () {
              // Branded Settings Action
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(LucideIcons.settings, size: 20, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'AI Mode',
              icon: LucideIcons.wand2,
              isSelected: _isAutoMode,
              selectedGradient: AppColors.aiGradient,
              onTap: () => setState(() => _isAutoMode = true),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              label: 'Manual',
              icon: LucideIcons.sliders,
              isSelected: !_isAutoMode,
              selectedGradient: AppColors.primaryGradient,
              onTap: () => setState(() => _isAutoMode = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required LinearGradient selectedGradient,
    required VoidCallback onTap,
  }) {
    return InteractiveScaleButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected ? selectedGradient : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: selectedGradient.colors.last.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? Colors.white : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualAlert() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle, size: 18, color: Color(0xFFEA580C)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Manual mode active — AI suggestions paused.',
              style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF9A3412)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterBudgetCard() {
    final waterUsedLiters = _waterUsage?['water_used_liters'] ?? 0;
    const budgetLiters = 28000.0;
    final progress = (waterUsedLiters / budgetLiters).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Water Budget',
            style: AppTextStyles.label.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeCap: StrokeCap.round,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(waterUsedLiters / 1000).toStringAsFixed(1)}',
                          style: AppTextStyles.dataValue.copyWith(color: Colors.white, fontSize: 24),
                        ),
                        Text(
                          'kL used',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBudgetItem('Used today', '$waterUsedLiters L'),
                    const SizedBox(height: 16),
                    _buildBudgetItem('Remaining', '${(budgetLiters - waterUsedLiters).toInt()} L'),
                    const SizedBox(height: 16),
                    _buildBudgetItem('Budget', '${budgetLiters.toInt()} L', isBold: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetItem(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
        Text(
          value,
          style: AppTextStyles.label.copyWith(
            color: Colors.white,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 16,
          ),
        ),
      ],
    );
  }

  Widget _buildZoneCard(Map<String, dynamic> zone) {
    final moisture = zone['current_moisture'] ?? 0;
    final name = zone['name'] ?? 'Zone';
    final crop = zone['crop_type'] ?? 'Unknown';
    final waterUsed = zone['water_used_today'] ?? '0';
    final isValveOn = zone['valve_state'] == true;
    final String zoneId = zone['zone_id'].toString();
    final mode = zone['operating_mode'] ?? 'OPTIMAL_RANGE';
    final isHeatStress = mode == 'HEAT_STRESS';

    // Premium styling parameters
    Color cardBorder;
    LinearGradient cardBg;
    if (isValveOn) {
      cardBorder = AppColors.accentGreen.withValues(alpha: 0.35);
      cardBg = const LinearGradient(
        colors: [Color(0xFFECFDF5), Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (isHeatStress) {
      cardBorder = AppColors.accentOrange.withValues(alpha: 0.35);
      cardBg = const LinearGradient(
        colors: [Color(0xFFFFF7ED), Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      cardBorder = AppColors.border;
      cardBg = const LinearGradient(
        colors: [Colors.white, Color(0xFFF8FAFC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: AppTextStyles.label.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (isValveOn) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(color: AppColors.accentGreen, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'IRRIGATING',
                                style: AppTextStyles.caption.copyWith(color: AppColors.accentGreen, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('$crop · $waterUsed L today', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                ],
              ),
              Text(
                '$moisture%',
                style: AppTextStyles.label.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isValveOn ? AppColors.accentBlue : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: moisture / 100,
              backgroundColor: const Color(0xFFE2E8F0),
              color: isValveOn ? AppColors.accentGreen : AppColors.accentBlue,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: isValveOn
                    ? _buildActionButton(
                        label: 'STOP WATERING',
                        icon: LucideIcons.octagon,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        isLoading: _irrigationLoading[zoneId] == true,
                        onTap: () => _handleManualStop(zone['zone_id']),
                      )
                    : (_isAutoMode
                        ? _buildActionButton(
                            label: isHeatStress ? 'AI: HEAT STRESS' : 'AI ACTIVE',
                            icon: isHeatStress ? LucideIcons.flame : LucideIcons.sparkles,
                            gradient: isHeatStress
                                ? const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)])
                                : AppColors.aiGradient,
                            onTap: () {},
                          )
                        : _buildActionButton(
                            label: 'IRRIGATE NOW',
                            icon: LucideIcons.droplets,
                            gradient: AppColors.primaryGradient,
                            isLoading: _irrigationLoading[zoneId] == true,
                            onTap: () => _handleManualIrrigate(zone['zone_id']),
                          )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Schedule',
                  icon: LucideIcons.calendar,
                  color: Colors.white,
                  textColor: AppColors.textPrimary,
                  borderColor: AppColors.border,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SchedulingScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    Color? color,
    LinearGradient? gradient,
    Color? textColor,
    Color? borderColor,
    bool isLoading = false,
    required VoidCallback onTap,
  }) {
    final isWhite = color == Colors.white;
    return InteractiveScaleButton(
      onTap: isLoading ? null : onTap,
      enabled: !isLoading,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color: isWhite ? Colors.white : (isLoading ? AppColors.textMuted.withValues(alpha: 0.3) : color),
          gradient: isWhite ? null : (isLoading ? null : gradient),
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: (!isWhite && !isLoading) ? [
            BoxShadow(
              color: (gradient?.colors.last ?? color ?? Colors.black).withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: isWhite ? AppColors.textPrimary : Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: AppTextStyles.label.copyWith(
                        color: textColor ?? (isWhite ? AppColors.textPrimary : Colors.white),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _handleManualIrrigate(dynamic zoneId) async {
    final String key = zoneId.toString();
    setState(() {
      _irrigationLoading[key] = true;
    });

    try {
      await _apiService.manualOverride(
        zoneId: key,
        action: 'irrigate',
        durationMin: 15,
        reason: 'Manual override from Control Center',
      );
      
      await _load(); // Refresh state dynamically

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.droplets, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('Irrigation started successfully for Zone $zoneId!', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: AppColors.accentGreen,
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
                Expanded(child: Text('Failed to start irrigation: $e', style: const TextStyle(fontWeight: FontWeight.bold))),
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

  Future<void> _handleManualStop(dynamic zoneId) async {
    final String key = zoneId.toString();
    setState(() {
      _irrigationLoading[key] = true;
    });

    try {
      await _apiService.manualOverride(
        zoneId: key,
        action: 'stop',
        reason: 'Stopped from Control Center',
      );
      
      await _load(); // Refresh state dynamically

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.octagon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('Irrigation stopped successfully for Zone $zoneId!', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: AppColors.accentRed,
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
                Expanded(child: Text('Failed to stop irrigation: $e', style: const TextStyle(fontWeight: FontWeight.bold))),
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
}

class InteractiveScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  const InteractiveScaleButton({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<InteractiveScaleButton> createState() => _InteractiveScaleButtonState();
}

class _InteractiveScaleButtonState extends State<InteractiveScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 80),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(_isHovered ? 1.03 : 1.0),
            transformAlignment: Alignment.center,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
