import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:aquasol_app/core/services/api_service.dart';
import 'package:aquasol_app/core/theme/app_colors.dart';
import 'package:aquasol_app/core/theme/app_text_styles.dart';
import 'package:aquasol_app/shared/widgets/input_field.dart';
import 'package:aquasol_app/core/services/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:aquasol_app/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      final result = await apiService.login(
        _phoneController.text,
        _passwordController.text,
      );

      if (result != null) {
        if (mounted) context.go('/splash');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed. Please check your credentials.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => _showLanguageSelector(context),
            icon: const Icon(LucideIcons.languages, size: 18),
            label: Text(langProvider.getLanguageName(), style: AppTextStyles.label.copyWith(fontSize: 12)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Logo Placeholder
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.droplets, color: AppColors.primary, size: 48),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(l10n.welcomeBack, style: AppTextStyles.screenTitle.copyWith(fontSize: 32, color: const Color(0xFF1B3D2F))),
              const SizedBox(height: 8),
              Text(l10n.signInToManage, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 48),
              
              InputField(
                label: l10n.emailAddress,
                placeholder: 'farmer@example.com',
                controller: _phoneController,
                prefixIcon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              
              Stack(
                children: [
                  InputField(
                    label: l10n.password,
                    placeholder: '••••••••',
                    controller: _passwordController,
                    prefixIcon: LucideIcons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                        size: 20,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                      child: Text(l10n.forgotPassword, style: AppTextStyles.label.copyWith(color: AppColors.primary, fontSize: 12)),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(l10n.signIn, style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(l10n.orContinueWith, style: AppTextStyles.caption),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(
                    child: _buildSocialButton(LucideIcons.smartphone, 'Mobile OTP'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSocialButton(LucideIcons.globe, 'Google'),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.dontHaveAccount, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: Text(l10n.signUpFree, style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.selectLanguage, style: AppTextStyles.cardTitle),
            const SizedBox(height: 24),
            _buildLangItem(context, langProvider, 'en', 'English', '🇺🇸'),
            _buildLangItem(context, langProvider, 'hi', 'Hindi', '🇮🇳'),
            _buildLangItem(context, langProvider, 'kn', 'Kannada', '🇮🇳'),
            _buildLangItem(context, langProvider, 'te', 'Telugu', '🇮🇳'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLangItem(BuildContext context, LanguageProvider provider, String code, String name, String flag) {
    final isSel = provider.locale.languageCode == code;
    return ListTile(
      onTap: () {
        provider.setLocale(Locale(code));
        Navigator.pop(context);
      },
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name, style: AppTextStyles.bodyMedium.copyWith(
        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
        color: isSel ? AppColors.primary : AppColors.textPrimary,
      )),
      trailing: isSel ? const Icon(LucideIcons.check, color: AppColors.primary) : null,
    );
  }

  Widget _buildSocialButton(IconData icon, String label) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.textPrimary),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.label),
          ],
        ),
      ),
    );
  }
}
