import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  Future<void> _finish(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Header
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 180,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    Text(
                      'Welcome to AquaSol',
                      style: AppTextStyles.screenTitle.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Intelligent irrigation management powered by AI and real-time field data.',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 48),

                    // Feature List
                    _buildFeatureItem(
                      icon: Icons.water_drop_rounded,
                      color: const Color(0xFF059669), // Emerald
                      title: 'Save Water',
                      description: 'Irrigate only when needed, driven by real sensor data.',
                    ),
                    const SizedBox(height: 24),
                    _buildFeatureItem(
                      icon: Icons.sensors_rounded,
                      color: const Color(0xFF0EA5E9), // Sky Blue
                      title: 'Live Monitoring',
                      description: 'Track soil moisture and weather conditions 24/7.',
                    ),
                    const SizedBox(height: 24),
                    _buildFeatureItem(
                      icon: Icons.psychology_rounded,
                      color: const Color(0xFF8B5CF6), // Purple
                      title: 'AI Advisory',
                      description: 'Our XGBoost model learns and decides the optimal watering window.',
                    ),
                    const SizedBox(height: 24),
                    _buildFeatureItem(
                      icon: Icons.qr_code_scanner_rounded,
                      color: const Color(0xFFF59E0B), // Amber
                      title: 'Easy Setup',
                      description: 'Scan your hardware QR codes and go live instantly.',
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Area
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _finish(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Get Started',
                    style: AppTextStyles.label.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.label.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
