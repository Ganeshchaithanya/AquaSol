import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/animated_interactive_card.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  List<dynamic> _faqCategories = [];
  List<dynamic> _filteredCategories = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFaqs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFaqs() async {
    try {
      final String response = await rootBundle.loadString('assets/faq.json');
      final data = await json.decode(response);
      setState(() {
        _faqCategories = data;
        _filteredCategories = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[FAQ] Error loading FAQ data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredCategories = _faqCategories;
      });
      return;
    }

    final List<dynamic> matchedCategories = [];
    for (var cat in _faqCategories) {
      final items = cat['items'] as List<dynamic>;
      final matchedItems = items.where((item) {
        final q = (item['question'] as String).toLowerCase();
        final a = (item['answer'] as String).toLowerCase();
        return q.contains(query) || a.contains(query);
      }).toList();

      if (matchedItems.isNotEmpty) {
        matchedCategories.add({
          'category': cat['category'],
          'items': matchedItems,
        });
      }
    }

    setState(() {
      _filteredCategories = matchedCategories;
    });
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case "Farm Setup & Configuration":
        return LucideIcons.sprout;
      case "Connectivity & Local Server":
        return LucideIcons.wifi;
      case "AI Decisions & Sensors":
        return LucideIcons.sparkles;
      case "Support & Troubleshooting":
      default:
        return LucideIcons.helpCircle;
    }
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName) {
      case "Farm Setup & Configuration":
        return AppColors.accentGreen;
      case "Connectivity & Local Server":
        return AppColors.accentBlue;
      case "AI Decisions & Sensors":
        return AppColors.accentPurple;
      case "Support & Troubleshooting":
      default:
        return AppColors.accentOrange;
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('[FAQ] Could not launch $urlString');
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
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'FAQ & Support',
          style: AppTextStyles.screenTitle.copyWith(fontSize: 22),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSearchBar(),
                  const SizedBox(height: 24),
                  if (_filteredCategories.isEmpty)
                    _buildNoResults()
                  else
                    ..._filteredCategories.map((cat) => _buildCategorySection(cat)),
                  const SizedBox(height: 16),
                  _buildSupportSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How can we help?',
          style: AppTextStyles.screenTitle.copyWith(fontSize: 28, height: 1.2),
        ),
        const SizedBox(height: 8),
        Text(
          'Find answers to common questions about farm configuration, system WiFi, offline operations, and smart sensor decisions.',
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.body.copyWith(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search topics, questions, WiFi details...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
          prefixIcon: const Icon(LucideIcons.search, color: AppColors.primary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, color: AppColors.textSecondary, size: 18),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.searchCode, size: 48, color: AppColors.accentOrange),
          const SizedBox(height: 16),
          Text('No matching questions found', style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            'Try searching for another keyword or check out the support channels below.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> category) {
    final name = category['category'] as String;
    final items = category['items'] as List<dynamic>;
    final icon = _getCategoryIcon(name);
    final color = _getCategoryColor(name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.sectionLabel.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => _buildFaqTile(item)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFaqTile(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondary,
          title: Text(
            item['question'],
            style: AppTextStyles.label.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            Text(
              item['answer'],
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Still need help?',
            style: AppTextStyles.sectionLabel.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.aiGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPurple.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.helpCircle, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    '24/7 Dedicated Support',
                    style: AppTextStyles.cardTitle.copyWith(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Our agricultural support engineers and intelligent AI system are here to ensure your irrigation runs perfectly.',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.85), height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildSupportButton(
                      'Email Us',
                      LucideIcons.mail,
                      () => _launchUrl('mailto:support@aquasol.io'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSupportButton(
                      'Call Help',
                      LucideIcons.phoneCall,
                      () => _launchUrl('tel:+18005557658'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _buildSupportButton(
                  'Chat with Solu AI',
                  LucideIcons.messageSquare,
                  () => context.push('/chatbot'),
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportButton(String label, IconData icon, VoidCallback onTap, {bool isPrimary = false}) {
    return AnimatedInteractiveCard(
      onTap: onTap,
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(vertical: 12),
      selectedBackgroundColor: isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.15),
      selectedBorderColor: Colors.transparent,
      isSelected: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isPrimary ? AppColors.accentPurple : Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: isPrimary ? AppColors.accentPurple : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
