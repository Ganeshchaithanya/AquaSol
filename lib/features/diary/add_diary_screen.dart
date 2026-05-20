import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';

class AddDiaryScreen extends StatefulWidget {
  const AddDiaryScreen({super.key});

  @override
  State<AddDiaryScreen> createState() => _AddDiaryScreenState();
}

class _AddDiaryScreenState extends State<AddDiaryScreen> {
  final _apiService = ApiService();
  String _selectedCategory = 'Observation';
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _costController = TextEditingController();
  bool _isLoading = false;
  bool _isSubsidyRelevant = true;
  
  List<dynamic> _zones = [];
  Map<String, dynamic>? _selectedZone;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Irrigation', 'icon': LucideIcons.droplets, 'color': AppColors.accentBlue},
    {'name': 'Fertilizer', 'icon': LucideIcons.zap, 'color': AppColors.accentOrange},
    {'name': 'Pest', 'icon': LucideIcons.bug, 'color': AppColors.accentRed},
    {'name': 'Observation', 'icon': LucideIcons.eye, 'color': AppColors.accentPurple},
    {'name': 'Harvest', 'icon': LucideIcons.shoppingBag, 'color': AppColors.accentGreen},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final zones = await _apiService.getZones();
    if (mounted) {
      setState(() {
        _zones = zones;
        if (_zones.isNotEmpty) _selectedZone = _zones.first;
      });
    }
  }

  Future<void> _saveEntry() async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some notes.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final title = _titleController.text.isNotEmpty 
        ? _titleController.text 
        : 'Manual $_selectedCategory';

    final result = await _apiService.logActivity(
      zoneId: _selectedZone?['zone_id']?.toString() ?? '',
      activityType: _selectedCategory.toLowerCase(),
      title: title,
      body: _noteController.text,
      metadata: {
        'cost': double.tryParse(_costController.text) ?? 0.0,
      },
      isSubsidy: _isSubsidyRelevant,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result != null && result['status'] == 'success') {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save entry.')),
      );
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
        title: Text('New Entry', style: AppTextStyles.screenTitle),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CATEGORY', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (c, i) => const SizedBox(width: 12),
                    itemBuilder: (c, i) {
                      final cat = _categories[i];
                      final isSel = _selectedCategory == cat['name'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat['name']),
                        child: Container(
                          width: 90,
                          decoration: BoxDecoration(
                            color: isSel ? cat['color'] : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSel ? cat['color'] : AppColors.border),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(cat['icon'], color: isSel ? Colors.white : cat['color'], size: 24),
                              const SizedBox(height: 8),
                              Text(cat['name'], style: AppTextStyles.caption.copyWith(color: isSel ? Colors.white : AppColors.textPrimary, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Text('TITLE', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Applied Urea',
                    hintStyle: AppTextStyles.bodySmall,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 32),
                Text('ESTIMATED COST (₹)', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                TextField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'e.g. 500',
                    hintStyle: AppTextStyles.bodySmall,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.landmark, color: AppColors.accentOrange, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Subsidy Relevant', style: AppTextStyles.label),
                            Text('Include this in government reports', style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isSubsidyRelevant,
                        onChanged: (val) => setState(() => _isSubsidyRelevant = val),
                        activeThumbColor: AppColors.accentOrange,
                        activeTrackColor: AppColors.accentOrange.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('ZONE', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          child: Text('${z['name']} · ${z['crop_type']}', style: AppTextStyles.label),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text('NOTES / OBSERVATIONS', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Describe what you observed...',
                    hintStyle: AppTextStyles.bodySmall,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 32),
                Text('ADD MEDIA', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildAddMediaButton(LucideIcons.camera, 'Camera'),
                    const SizedBox(width: 16),
                    _buildAddMediaButton(LucideIcons.image, 'Gallery'),
                  ],
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMediaButton(IconData icon, String label) {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
