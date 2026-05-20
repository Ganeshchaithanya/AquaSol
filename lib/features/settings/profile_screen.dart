import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/language_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _dashboard;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      _user = await apiService.getMe();
      _dashboard = await apiService.getDashboard();
      if (_user != null) {
        _nameController.text = _user!['name'] ?? '';
      }
      if (_dashboard != null) {
        _farmController.text = _dashboard!['name'] ?? '';
        _locationController.text = _dashboard!['location'] ?? '';
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLanguageSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.language, style: AppTextStyles.cardTitle),
              const SizedBox(height: 24),
              _buildLangOption(context, 'en', 'English', 'English'),
              _buildLangOption(context, 'hi', 'Hindi', 'हिंदी'),
              _buildLangOption(context, 'kn', 'Kannada', 'ಕನ್ನಡ'),
              _buildLangOption(context, 'te', 'Telugu', 'తెలుగు'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLangOption(BuildContext context, String code, String label, String native) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isSel = langProvider.locale.languageCode == code;

    return GestureDetector(
      onTap: () async {
        final apiService = Provider.of<ApiService>(context, listen: false);
        langProvider.setLocale(Locale(code));
        
        // Sync to backend
        if (_user != null) {
          await apiService.updateLanguagePreference(_user!['id'], code);
        }
        
        if (context.mounted) Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Text(native, style: AppTextStyles.label.copyWith(color: isSel ? AppColors.primary : AppColors.textPrimary)),
            const Spacer(),
            if (isSel) const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAvatar(String url) async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.updateProfile({
        'avatar_url': url,
      });
      setState(() {
        if (_user != null) {
          _user!['avatar_url'] = url;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
      }
    } catch (e) {
      debugPrint('Avatar update error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAvatarPicker() {
    final avatars = [
      {
        'name': 'Tech Farmer',
        'url': 'https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?auto=format&fit=crop&q=80&w=150'
      },
      {
        'name': 'Drone Expert',
        'url': 'https://images.unsplash.com/photo-1580618672591-eb180b1a973f?auto=format&fit=crop&q=80&w=150'
      },
      {
        'name': 'Agronomist',
        'url': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=150'
      },
      {
        'name': 'Organic Expert',
        'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=150'
      },
      {
        'name': 'Hydro Engineer',
        'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=150'
      },
      {
        'name': 'AI Advisor',
        'url': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&q=80&w=150'
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Profile Avatar', style: AppTextStyles.cardTitle),
              const SizedBox(height: 24),
              SizedBox(
                height: 125,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: avatars.length,
                  itemBuilder: (context, idx) {
                    final av = avatars[idx];
                    return GestureDetector(
                      onTap: () {
                        _updateAvatar(av['url']!);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundImage: NetworkImage(av['url']!),
                            ),
                            const SizedBox(height: 8),
                            Text(av['name']!, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  final _nameController = TextEditingController();
  final _farmController = TextEditingController();
  final _locationController = TextEditingController();

  bool _notificationsEnabled = true;
  String _preferredUnits = 'Metric';

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.updateProfile({
        'name': _nameController.text,
        // Farm name update would be a separate endpoint usually or handled here
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!')));
        Navigator.pop(context);
        _load();
      }
    } catch (e) {
      debugPrint('Save error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditProfileSheet() {
    _nameController.text = _user?['name'] ?? 'Farmer';
    _farmController.text = _dashboard?['name'] ?? 'My Farm';
    _locationController.text = _dashboard?['location'] ?? 'Karnataka';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            Text('Edit Profile', style: AppTextStyles.screenTitle),
            const SizedBox(height: 32),
            _buildEditField('Full Name', _nameController),
            const SizedBox(height: 20),
            _buildEditField('Farm Name', _farmController),
            const SizedBox(height: 20),
            _buildEditField('Location', _locationController),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary),
        ),
        title: Text(l10n.profile, style: AppTextStyles.screenTitle),
        actions: [
          IconButton(
            onPressed: () => _showLanguageSelector(context),
            icon: const Icon(LucideIcons.languages, color: AppColors.primary),
          ),
          IconButton(onPressed: () {}, icon: const Icon(LucideIcons.bell, color: AppColors.primary)),
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(_user?['avatar_url'] ?? 'https://ui-avatars.com/api/?name=${_user?['name'] ?? 'Farmer'}&background=random'),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHero(l10n),
            const SizedBox(height: 24),
            _buildStatsRow(l10n),
            const SizedBox(height: 32),
            _buildLanguageSelector(langProvider, l10n),
            const SizedBox(height: 32),
            Text(l10n.settings.toUpperCase(), style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            _buildSettingsTile(
              LucideIcons.bell, 
              'Notifications', 
              _notificationsEnabled ? 'Enabled' : 'Disabled', 
              () {
                setState(() => _notificationsEnabled = !_notificationsEnabled);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Notifications ${_notificationsEnabled ? "Enabled" : "Disabled"}'),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(milliseconds: 800),
                  ),
                );
              }
            ),
            _buildSettingsTile(
              LucideIcons.map, 
              'Units', 
              _preferredUnits, 
              () {
                setState(() => _preferredUnits = _preferredUnits == 'Metric' ? 'Imperial' : 'Metric');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Unit preference switched to $_preferredUnits'),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(milliseconds: 800),
                  ),
                );
              }
            ),
            _buildSettingsTile(
              LucideIcons.wifi, 
              'Connected Devices', 
              '${_dashboard?['total_nodes'] ?? 0} Active', 
              () {
                context.push('/setup');
              }
            ),
            const SizedBox(height: 32),
            Text('SUPPORT', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            _buildSettingsTile(
              LucideIcons.helpCircle, 
              'Help Center', 
              'Ask Solu AI', 
              () {
                context.push('/chatbot');
              }
            ),
            _buildSettingsTile(
              LucideIcons.info, 
              'About AquaSol', 
              'v2.0.4', 
              _showAboutDialog
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('access_token');
                  if (context.mounted) context.go('/splash');
                },
                icon: const Icon(LucideIcons.logOut, color: AppColors.accentRed, size: 20),
                label: Text('Sign Out', style: AppTextStyles.label.copyWith(color: AppColors.accentRed)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFEE2E2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(LanguageProvider langProvider, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.languages, color: AppColors.primary),
          const SizedBox(width: 16),
          Text(l10n.language, style: AppTextStyles.label),
          const Spacer(),
          GestureDetector(
            onTap: () => _showLanguageSelector(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
              child: Text(langProvider.getLanguageName(), style: AppTextStyles.label.copyWith(color: AppColors.primary, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHero(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.healthGradient,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showAvatarPicker,
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 4),
                    image: DecorationImage(
                      image: NetworkImage(_user?['avatar_url'] ?? 'https://ui-avatars.com/api/?name=${_user?['name'] ?? 'Farmer'}&background=random'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.camera, color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_user?['name'] ?? 'Farmer', style: AppTextStyles.screenTitle.copyWith(color: Colors.white, fontSize: 22)),
                    IconButton(
                      onPressed: _showEditProfileSheet,
                      icon: const Icon(LucideIcons.edit3, color: Colors.white, size: 20),
                    ),
                  ],
                ),
                Text('${_dashboard?['name'] ?? 'Farm'} · ${_dashboard?['location'] ?? 'India'}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
                  ),
                  child: Text('PRO MEMBER', style: AppTextStyles.caption.copyWith(color: AppColors.accentGreen, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AppLocalizations l10n) {
    return Row(
      children: [
        _buildStatItem('${_dashboard?['total_acres'] ?? 0}', 'ACRES'),
        _buildStatItem('${_dashboard?['total_zones'] ?? 0}', 'ZONES'),
        _buildStatItem('${_dashboard?['active_zones'] ?? 0}', 'ACTIVE'),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.dataValue.copyWith(color: AppColors.primary, fontSize: 24)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption.copyWith(letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String value, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        title: Text(title, style: AppTextStyles.label.copyWith(fontSize: 16)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value.isNotEmpty) Text(value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            const Icon(LucideIcons.info, color: AppColors.primary),
            const SizedBox(width: 12),
            Text('About AquaSol V2', style: AppTextStyles.label.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Column(
                children: [
                  Icon(LucideIcons.sprout, size: 48, color: AppColors.accentGreen),
                  SizedBox(height: 8),
                  Text('AquaSol v2.0.4', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Enterprise Farm OS', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'An intelligent, event-driven real-time operating system for modern high-yield agriculture.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            _buildAboutInfoRow('Precision AI Core', 'LSTM + XGBoost'),
            _buildAboutInfoRow('Reliability Matrix', 'Virtual Sensing'),
            _buildAboutInfoRow('Database Ingest', 'Neon PostgreSQL'),
            _buildAboutInfoRow('Language Engine', 'En, Hi, Kn, Te'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
        ],
      ),
    );
  }
}
