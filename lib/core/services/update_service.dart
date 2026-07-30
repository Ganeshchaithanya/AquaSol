import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class UpdateService {
  static const String _backendVersionUrl =
      'https://aquasol-software.onrender.com/api/v1/app/version';
  static const String appDownloadUrl =
      'https://aquasol-software.onrender.com/api/v1/app/download';

  static bool _hasChecked = false;
  static bool _isDialogShowing = false;

  /// Checks for updates silently and pops up a modal if a new release is found.
  /// If [force] is true, provides active feedback via SnackBar.
  static Future<void> checkForUpdates(BuildContext context, {bool force = false}) async {
    if (_hasChecked && !force) {
      debugPrint('[UpdateService] Update check already performed in this session. Skipping.');
      return;
    }
    _hasChecked = true;

    if (force && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Checking for AquaSol updates...'),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    try {
      // 1. Get current installed app version including build number (e.g. "3.6.0+0")
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      // 2. Fetch the latest release info from Render API
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 5);
      dio.options.receiveTimeout = const Duration(seconds: 5);
      
      final response = await dio.get(_backendVersionUrl);
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data = response.data;
        final String? onlineVersion = data['version']; // e.g. "3.7.0+1"

        if (onlineVersion != null) {
          final isNewer = _isNewerVersion(currentVersion, onlineVersion);
          if (isNewer && context.mounted) {
            if (_isDialogShowing) return;
            _showUpdateDialog(context, currentVersion, onlineVersion);
          } else if (force && context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You are on the latest version of AquaSol (v$currentVersion)!'),
                backgroundColor: AppColors.accentGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to check for updates: $e');
      if (force && context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to connect to update server. Check your internet connection.'),
            backgroundColor: AppColors.accentRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  /// Compares semantic versions (e.g. "3.6.0+0" and "3.6.0+1")
  static bool _isNewerVersion(String currentVersion, String onlineVersion) {
    // Clean strings (remove leading 'v' or 'V' and trim whitespace)
    final cleanCurrent = currentVersion.replaceAll(RegExp(r'^[vV]'), '').trim();
    final cleanOnline = onlineVersion.replaceAll(RegExp(r'^[vV]'), '').trim();

    // Split version from build number (separated by '+')
    final currentParts = cleanCurrent.split('+');
    final onlineParts = cleanOnline.split('+');

    final currentVerStr = currentParts[0];
    final onlineVerStr = onlineParts[0];

    final currentBuildStr = currentParts.length > 1 ? currentParts[1] : '0';
    final onlineBuildStr = onlineParts.length > 1 ? onlineParts[1] : '0';

    // Parse dot-separated version components (e.g., "3.6.0" -> [3, 6, 0])
    final currentSemVer = currentVerStr.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final onlineSemVer = onlineVerStr.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Ensure we have at least 3 parts (major, minor, patch)
    while (currentSemVer.length < 3) {
      currentSemVer.add(0);
    }
    while (onlineSemVer.length < 3) {
      onlineSemVer.add(0);
    }

    // Compare major, minor, patch
    for (int i = 0; i < 3; i++) {
      final currentPart = currentSemVer[i];
      final onlinePart = onlineSemVer[i];

      if (onlinePart > currentPart) return true;
      if (onlinePart < currentPart) return false;
    }

    // If semantic versions are identical, compare build numbers
    final currentBuild = int.tryParse(currentBuildStr) ?? 0;
    final onlineBuild = int.tryParse(onlineBuildStr) ?? 0;

    return onlineBuild > currentBuild;
  }

  /// Displays the custom update dialog inside the active view context
  static void _showUpdateDialog(
      BuildContext context, String currentVersion, String newVersion) {
    _isDialogShowing = true;
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
                          onPressed: () async {
                            _isDialogShowing = false;
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('last_seen_update_version', newVersion);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
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
                            _isDialogShowing = false;
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('last_seen_update_version', newVersion);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                            final Uri url = Uri.parse(appDownloadUrl);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              debugPrint('Could not launch $appDownloadUrl');
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
