import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final apiService = ApiService();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout', style: AppTextStyles.cardTitle),
        content: Text('Are you sure you want to log out of your AquaSol account?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Logout', style: AppTextStyles.label.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await apiService.logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.home,
                  label: 'Home Dashboard',
                  route: '/home',
                ),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.sprout,
                  label: 'My Farm & Zones',
                  route: '/farm',
                ),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.bell,
                  label: 'System Alerts',
                  route: '/alerts',
                ),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.activity,
                  label: 'Diagnostics & Health',
                  route: '/system-health',
                ),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.messageSquare,
                  label: 'AI Assistant (Solu)',
                  route: '/chatbot',
                ),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.helpCircle,
                  label: 'FAQ & Support',
                  route: '/faq',
                  iconColor: AppColors.accentOrange,
                ),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.user,
                  label: 'My Profile',
                  route: '/profile',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Divider(color: AppColors.border, height: 1),
                ),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.logOut,
                  label: 'Log Out',
                  onTap: () => _handleLogout(context),
                  iconColor: AppColors.accentRed,
                ),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.droplets,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AquaSol AI',
                style: AppTextStyles.screenTitle.copyWith(
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: NetworkImage('https://i.pravatar.cc/150?u=ramesh'),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ramesh Kumar',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Premium Grower',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? route,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    final currentPath = GoRouterState.of(context).uri.path;
    final isSelected = route != null && currentPath == route;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected 
              ? AppColors.primary 
              : (iconColor ?? AppColors.textSecondary),
          size: 20,
        ),
        title: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () {
          Navigator.pop(context); // Close the drawer first
          if (onTap != null) {
            onTap();
          } else if (route != null) {
            context.push(route);
          }
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            'AquaSol v2.0.1+2',
            style: AppTextStyles.caption.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            'Decisions Powered by Solu AI',
            style: AppTextStyles.caption.copyWith(
              fontSize: 9,
              color: AppColors.accentPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
