import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class UpdateService {
  static const String _githubReleaseUrl =
      'https://api.github.com/repos/Ganeshchaithanya/AquaSol/releases/latest';
  static const String _downloadUrl =
      'https://github.com/Ganeshchaithanya/AquaSol/releases/latest/download/app-release.apk';

  /// Checks for updates silently and pops up a modal if a new release is found.
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      // 1. Get current installed app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 2. Fetch the latest release info from GitHub API
      final dio = Dio();
      // Set reasonable timeouts so startup is not blocked if offline
      dio.options.connectTimeout = const Duration(seconds: 4);
      dio.options.receiveTimeout = const Duration(seconds: 4);
      
      final response = await dio.get(_githubReleaseUrl);
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data = response.data;
        final String? onlineVersion = data['tag_name']; // e.g. "v1.0.1" or "2.0.0"

        if (onlineVersion != null) {
          final isNewer = _isNewerVersion(currentVersion, onlineVersion);
          if (isNewer && context.mounted) {
            _showUpdateDialog(context, currentVersion, onlineVersion);
          }
        }
      }
    } catch (e) {
      // Fail silently to prevent interrupting the app startup flow
      debugPrint('Failed to check for updates: $e');
    }
  }

  /// Compares semantic versions (e.g. "1.0.0" and "1.0.1")
  static bool _isNewerVersion(String currentVersion, String onlineVersion) {
    final cleanCurrent = currentVersion.replaceAll(RegExp(r'^v'), '').trim();
    final cleanOnline = onlineVersion.replaceAll(RegExp(r'^v'), '').trim();

    final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final onlineParts = cleanOnline.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Ensure we have at least 3 parts (major, minor, patch)
    while (currentParts.length < 3) {
      currentParts.add(0);
    }
    while (onlineParts.length < 3) {
      onlineParts.add(0);
    }

    for (int i = 0; i < 3; i++) {
      final currentPart = currentParts[i];
      final onlinePart = onlineParts[i];

      if (onlinePart > currentPart) return true;
      if (onlinePart < currentPart) return false;
    }
    return false;
  }

  /// Displays the custom update dialog inside the active view context
  static void _showUpdateDialog(
      BuildContext context, String currentVersion, String newVersion) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force them to choose
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Prevent physical back button escape
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Sparkle/Droplet icon header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_alt_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Headline title
                  Text(
                    'Update Available!',
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Version stats
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'v$currentVersion',
                          style: AppTextStyles.bodySmall.copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          'v$newVersion',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Narrative explanation
                  Text(
                    'A new and improved version of AquaSol is available! Update now to experience enhanced robust controls, dynamic splash screen scaling, and custom branding assets.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  // Dialog buttons
                  Row(
                    children: [
                      // Dismiss button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Later',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Action update button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final Uri url = Uri.parse(_downloadUrl);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              debugPrint('Could not launch $_downloadUrl');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: Text(
                            'Update Now',
                            style: AppTextStyles.label.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
