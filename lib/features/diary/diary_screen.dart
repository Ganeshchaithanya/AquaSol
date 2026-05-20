import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _apiService = ApiService();
  List<dynamic> _entries = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getDiary();
      if (mounted) {
        setState(() {
          _entries = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredEntries {
    if (_selectedFilter == 'All') return _entries;
    return _entries.where((e) => e['type'].toString().toLowerCase() == _selectedFilter.toLowerCase()).toList();
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
        title: Text('Farm Diary', style: AppTextStyles.screenTitle),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.search, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 20),
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage('https://i.pravatar.cc/150?u=ramesh'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEntries.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _filteredEntries.length,
                          itemBuilder: (context, index) {
                            final entry = _filteredEntries[index];
                            final DateTime date = DateTime.parse(entry['timestamp']);
                            final bool isLast = index == _filteredEntries.length - 1;
                            
                            bool showDateHeader = false;
                            if (index == 0) {
                              showDateHeader = true;
                            } else {
                              final prevDate = DateTime.parse(_filteredEntries[index - 1]['timestamp']);
                              if (DateFormat('yyyy-MM-dd').format(date) != DateFormat('yyyy-MM-dd').format(prevDate)) {
                                showDateHeader = true;
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showDateHeader) _buildGroupHeader(DateFormat('EEEE — MMMM dd, yyyy').format(date).toUpperCase()),
                                _buildTimelineItem(
                                  icon: _getIcon(entry['type']),
                                  color: _getColor(entry['type']),
                                  title: entry['title'] ?? 'Untitled',
                                  desc: entry['description'] ?? '',
                                  time: DateFormat('hh:mm a').format(date),
                                  isLast: isLast,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await context.push('/farm/diary/add');
          if (res == true) _load();
        },
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.bookOpen, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No diary entries yet.', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
          TextButton(onPressed: _load, child: const Text('Refresh')),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'irrigation': return LucideIcons.droplets;
      case 'fertilizer': return LucideIcons.zap;
      case 'pest': return LucideIcons.bug;
      case 'harvest': return LucideIcons.shoppingBag;
      case 'observation': return LucideIcons.eye;
      default: return LucideIcons.fileText;
    }
  }

  Color _getColor(String type) {
    switch (type.toLowerCase()) {
      case 'irrigation': return AppColors.accentBlue;
      case 'fertilizer': return AppColors.accentOrange;
      case 'pest': return AppColors.accentRed;
      case 'harvest': return AppColors.accentGreen;
      case 'observation': return AppColors.accentPurple;
      default: return AppColors.textSecondary;
    }
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Irrigation', 'Fertilizer', 'Pest', 'Observation', 'Harvest'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: filters.map((f) {
          bool active = _selectedFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? AppColors.primary : AppColors.border),
              ),
              child: Text(
                f,
                style: AppTextStyles.label.copyWith(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGroupHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 16),
      child: Text(text, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required String time,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: AppTextStyles.label.copyWith(fontSize: 16)),
                    Text(time, style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
