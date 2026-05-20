import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';

class SchedulingScreen extends StatefulWidget {
  const SchedulingScreen({super.key});

  @override
  State<SchedulingScreen> createState() => _SchedulingScreenState();
}

class _SchedulingScreenState extends State<SchedulingScreen> {
  final _apiService = ApiService();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 6, minute: 0);
  final List<String> _selectedDays = ['Mon', 'Wed', 'Fri'];
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  List<dynamic> _zones = [];
  Map<String, dynamic>? _selectedZone;
  bool _isAcreWide = false;
  String _mode = 'manual';
  int _durationMin = 45;
  int _intensity = 80;
  String? _acreId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.getDashboard();
      final zones = await _apiService.getZones();
      if (mounted) {
        setState(() {
          _zones = zones;
          if (_zones.isNotEmpty) _selectedZone = _zones.first;
          // Get acre_id from dashboard (assuming it's in the response)
          // For now we'll fetch from the first zone's acre_id or similar
          if (_zones.isNotEmpty) {
            _acreId = _zones.first['acre_id']; 
          }
        });
      }
    } catch (e) {
      debugPrint('Schedule load error: $e');
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
        title: Text(AppLocalizations.of(context)!.irrigationSchedule, style: AppTextStyles.screenTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.selectTarget, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeToggle(AppLocalizations.of(context)!.individualZone, !_isAcreWide, () => setState(() => _isAcreWide = false)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeToggle(AppLocalizations.of(context)!.completeAcre, _isAcreWide, () => setState(() => _isAcreWide = true)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_isAcreWide)
                    _buildZoneSelector()
                  else
                    _buildAcreSelector(),
                  
                  const SizedBox(height: 32),
                  Text(AppLocalizations.of(context)!.dateTime, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPickerCard(
                          icon: LucideIcons.calendar,
                          label: AppLocalizations.of(context)!.date,
                          value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) setState(() => _selectedDate = date);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPickerCard(
                          icon: LucideIcons.clock,
                          label: AppLocalizations.of(context)!.time,
                          value: _selectedTime.format(context),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (time != null) setState(() => _selectedTime = time);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(AppLocalizations.of(context)!.repeatOn, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _days.map((day) {
                      final isSel = _selectedDays.contains(day);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSel) {
                              _selectedDays.remove(day);
                            } else {
                              _selectedDays.add(day);
                            }
                          });
                        },
                        child: Container(
                          width: 60,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                          ),
                          child: Text(
                            day,
                            style: AppTextStyles.label.copyWith(color: isSel ? Colors.white : AppColors.textPrimary, fontSize: 13),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  Text(AppLocalizations.of(context)!.mode, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTypeToggle(AppLocalizations.of(context)!.manualTimer, _mode == 'manual', () => setState(() => _mode = 'manual')),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeToggle(AppLocalizations.of(context)!.aiWindow, _mode == 'auto', () => setState(() => _mode = 'auto')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(AppLocalizations.of(context)!.durationIntensity, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                    child: Column(
                      children: [
                        _buildSliderRow(AppLocalizations.of(context)!.duration, '$_durationMin min', _durationMin / 120, (val) => setState(() => _durationMin = (val * 120).toInt())),
                        const Divider(height: 32),
                        _buildSliderRow(AppLocalizations.of(context)!.intensity, '$_intensity%', _intensity / 100, (val) => setState(() => _intensity = (val * 100).toInt())),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(AppLocalizations.of(context)!.confirmSchedule, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildTypeToggle(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: AppTextStyles.label.copyWith(color: isSelected ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }

  Widget _buildZoneSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: _selectedZone,
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown, color: AppColors.textMuted, size: 20),
          onChanged: (val) => setState(() => _selectedZone = val),
          items: _zones.map((z) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: z,
              child: Row(
                children: [
                  const Icon(LucideIcons.mapPin, color: AppColors.primary, size: 20),
                  const SizedBox(width: 16),
                  Text('${z['name']} · ${z['crop_type']}', style: AppTextStyles.label),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAcreSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          const Icon(LucideIcons.layers, color: AppColors.primary, size: 20),
          const SizedBox(width: 16),
          Text(AppLocalizations.of(context)!.acreAllZones, style: AppTextStyles.label),
          const Spacer(),
          const Icon(LucideIcons.chevronDown, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }

  Widget _buildPickerCard({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.textMuted, size: 16),
                const SizedBox(width: 8),
                Text(label, style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.label),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow(String label, String value, double progress, Function(double) onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.label),
            Text(value, style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withValues(alpha: 0.1),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 3),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Future<void> _handleConfirm() async {
    final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    
    final res = await _apiService.createSchedule(
      label: _isAcreWide ? AppLocalizations.of(context)!.acreWideIrrigation : AppLocalizations.of(context)!.zoneSchedule(_selectedZone?['name'] ?? ''),
      zoneId: _isAcreWide ? null : _selectedZone?['zone_id'],
      acreId: _isAcreWide ? _acreId : null,
      time: timeStr,
      days: _selectedDays,
      durationMin: _durationMin,
      intensity: _intensity,
      mode: _mode,
    );

    if (mounted) {
      if (res != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.scheduleSuccess)),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.scheduleError)),
        );
      }
    }
  }
}
