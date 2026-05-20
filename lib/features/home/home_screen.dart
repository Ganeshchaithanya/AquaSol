import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';
import 'package:provider/provider.dart';
import '../../core/services/language_provider.dart';
import '../../shared/widgets/animated_interactive_card.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic>? _dashboard;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final data = await _apiService.getDashboard();
      if (mounted) {
        setState(() {
          _dashboard = data;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Home load error: $e');
      final isAuthError = e.toString().contains('401') || e.toString().contains('403') || e.toString().contains('Unauthorized');
      if (isAuthError) {
        await _apiService.logout();
        if (mounted) {
          context.go('/login');
          return;
        }
      }
      if (mounted) {
        setState(() => _hasError = true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
              Text(l10n.selectLanguage, style: AppTextStyles.cardTitle),
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

    return AnimatedInteractiveCard(
      onTap: () async {
        langProvider.setLocale(Locale(code));
        if (context.mounted) Navigator.pop(context);
      },
      isSelected: isSel,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(native, style: AppTextStyles.label.copyWith(color: isSel ? AppColors.primary : AppColors.textPrimary)),
          const Spacer(),
          if (isSel) const Icon(LucideIcons.checkCircle2, color: AppColors.primary, size: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_hasError) {
      return _buildConnectionErrorState();
    }

    if (_dashboard == null) {
      return _buildNoFarmState();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(l10n),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildGreeting(l10n),
            const SizedBox(height: 24),
            _buildHealthHero(),
            const SizedBox(height: 24),
            _buildGatewayStatus(),
            const SizedBox(height: 24),
            _buildMetricsGrid(),
            const SizedBox(height: 24),
            _buildAIAdvisory(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 32),
            Text('Extended Features', style: AppTextStyles.sectionLabel),
            const SizedBox(height: 16),
            _buildExtendedFeaturesGrid(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionErrorState() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.wifiOff, size: 64, color: AppColors.accentRed),
              ),
              const SizedBox(height: 32),
              Text(
                'Connection Error',
                style: AppTextStyles.screenTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We can\'t reach the AquaSol server. Please ensure the backend is running and you are connected to the network.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _load,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Retry Connection',
                    style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoFarmState() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.sprout, size: 64, color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to AquaSol',
                style: AppTextStyles.screenTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You haven\'t set up your farm yet. Connect your devices and configure your zones to start smart irrigation.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/farm-setup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Setup My Farm',
                    style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _load,
                child: const Text('Already set up? Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.droplets,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.dashboard,
            style: AppTextStyles.screenTitle.copyWith(fontSize: 22),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _showLanguageSelector(context),
          icon: const Icon(LucideIcons.languages, color: AppColors.primary, size: 24),
        ),
        IconButton(
          onPressed: () => context.push('/alerts'),
          icon: Stack(
            children: [
              const Icon(LucideIcons.bell, color: AppColors.primary, size: 28),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.accentRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            margin: const EdgeInsets.only(right: 20),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: NetworkImage('https://i.pravatar.cc/150?u=ramesh'),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildGreeting(AppLocalizations l10n) {
    final rawName = _dashboard?['name'] ?? 'Farmer';
    final userName = rawName.contains("'") ? rawName.split("'")[0] : rawName;
    final temp = _dashboard?['weather']?['temperature'] ?? '--';
    final condition = _dashboard?['weather']?['condition'] ?? '--';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.greeting}, $userName',
          style: AppTextStyles.screenTitle.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              LucideIcons.cloudSun,
              color: AppColors.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text('$temp°C, $condition', style: AppTextStyles.bodyMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthHero() {
    final score = _dashboard?['metrics']?['health_score'];
    final displayScore = score?.toString() ?? '--';
    String status = score != null ? 'Optimal' : '--';
    if (score != null && score < 60) {
      status = 'Critical';
    } else if (score != null && score < 85) {
      status = 'Caution';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.healthGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Farm Health',
                style: AppTextStyles.label.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                displayScore,
                style: AppTextStyles.dataDisplay.copyWith(
                  color: Colors.white,
                  fontSize: 64,
                ),
              ),
              Text(
                '/100',
                style: AppTextStyles.dataDisplay.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGatewayStatus() {
    final master = _dashboard?['master_status'];
    if (master == null) return const SizedBox.shrink();

    final rain = master['rain_detected'] ?? false;
    final flow = master['flow_rate'] ?? 0.0;
    final battery = master['battery_pct'] ?? 0;
    final lastSeen = master['last_seen'] != null 
        ? DateTime.parse(master['last_seen']).toLocal() 
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.router, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text('Gateway Status', style: AppTextStyles.label),
                ],
              ),
              if (lastSeen != null)
                Text(
                  'Live',
                  style: AppTextStyles.caption.copyWith(color: AppColors.accentGreen, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGatewayMetric(
                'Rain', 
                rain ? 'Detected' : 'None', 
                rain ? LucideIcons.cloudRain : LucideIcons.sun,
                rain ? AppColors.accentBlue : AppColors.textMuted
              ),
              _buildGatewayMetric(
                'Flow', 
                '${flow.toStringAsFixed(1)} L/m', 
                LucideIcons.droplet, 
                AppColors.accentBlue
              ),
              _buildGatewayMetric(
                'Battery', 
                '$battery%', 
                battery > 20 ? LucideIcons.batteryFull : LucideIcons.batteryLow, 
                battery > 20 ? AppColors.accentGreen : AppColors.accentRed
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGatewayMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.label.copyWith(fontSize: 14)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    final activeZones = _dashboard?['active_zones'];
    final totalZones = _dashboard?['total_zones'];
    final totalAlerts = _dashboard?['total_alerts'];

    final waterToday = _dashboard?['metrics']?['water_used_today'];
    final aiDecisions = _dashboard?['metrics']?['ai_decisions_count'];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildMetricCard(
          "Today's Water",
          waterToday?.toString() ?? "--",
          "L",
          LucideIcons.droplets,
          AppColors.accentBlue,
        ),
        _buildMetricCard(
          "Active Zones",
          (activeZones != null && totalZones != null) ? "$activeZones/$totalZones" : "--",
          "On",
          LucideIcons.activity,
          AppColors.accentGreen,
        ),
        _buildMetricCard(
          "AI Decisions",
          aiDecisions?.toString() ?? "--",
          "",
          LucideIcons.sparkles,
          AppColors.accentPurple,
        ),
        _buildMetricCard(
          "Alerts",
          totalAlerts?.toString() ?? "--",
          "New",
          LucideIcons.shield,
          AppColors.accentOrange,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return AnimatedInteractiveCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.dataValue.copyWith(fontSize: 28),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIAdvisory() {
    final advisory = _dashboard?['metrics']?['advisory'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accentPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.accentPurple.withValues(alpha: 0.1),
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
                  color: AppColors.accentPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: AppColors.accentPurple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Advisory',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.accentPurple,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            advisory != null 
                ? (advisory['text'] ?? 'System suggests no changes currently.')
                : 'Welcome to AquaSol! Once your nodes are paired, Solu will provide real-time irrigation advice here.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildAdvisoryButton(
                'Approve',
                AppColors.accentPurple,
                Colors.white,
                () async {
                  setState(() => _isLoading = true);
                  await _apiService.handleAdvisoryAction(
                    zoneId: advisory['zone_id'],
                    action: 'approve',
                  );
                  _load();
                },
              ),
              const SizedBox(width: 12),
              _buildAdvisoryButton(
                'Dismiss',
                Colors.transparent,
                AppColors.accentPurple,
                () async {
                  setState(() => _isLoading = true);
                  await _apiService.handleAdvisoryAction(
                    zoneId: advisory['zone_id'],
                    action: 'dismiss',
                  );
                  _load();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisoryButton(
    String label,
    Color bg,
    Color text,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: AnimatedInteractiveCard(
        onTap: onTap,
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(vertical: 10),
        selectedBackgroundColor: bg == Colors.transparent ? Colors.transparent : bg,
        selectedBorderColor: bg == Colors.transparent ? AppColors.accentPurple : Colors.transparent,
        isSelected: bg != Colors.transparent, // Highlight the "Approve" button
        child: SizedBox(
          width: double.infinity,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(color: text),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            _buildActionButton(
              'Irrigate Now',
              LucideIcons.droplets,
              AppColors.accentBlue,
              () => context.push('/control'),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              'Run Diagnostic',
              LucideIcons.activity,
              AppColors.accentGreen,
              () => context.push('/system-health'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildActionButton(
              'Crop Planner',
              LucideIcons.calendar,
              AppColors.accentBlue,
              () => context.push('/farm/planner'),
            ),
            const SizedBox(width: 12),
            _buildActionButton(
              'Ask Solu',
              LucideIcons.messageCircle,
              AppColors.accentPurple,
              () => context.push('/chatbot'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: AnimatedInteractiveCard(
        onTap: onTap,
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.label),
          ],
        ),
      ),
    );
  }

  Widget _buildExtendedFeaturesGrid() {
    // Derive the first zone id dynamically from the loaded dashboard
    final zones = _dashboard?['zones'] as List?;
    final firstZoneId = (zones != null && zones.isNotEmpty)
        ? (zones[0]['zone_id']?.toString() ?? 'A')
        : 'A';

    final features = [
      {
        'label': 'Biology',
        'icon': LucideIcons.leaf,
        'color': AppColors.accentGreen,
        'route': '/farm/zone/$firstZoneId/biology',
      },
      {
        'label': 'Stage',
        'icon': LucideIcons.layoutGrid,
        'color': AppColors.accentGreen,
        'route': '/farm/stage/$firstZoneId',
      },
      {
        'label': 'Diary',
        'icon': LucideIcons.book,
        'color': AppColors.accentOrange,
        'route': '/farm/diary',
      },
      {
        'label': 'Reports',
        'icon': LucideIcons.fileText,
        'color': AppColors.accentBlue,
        'route': '/farm/diary/reports',
      },
      {
        'label': 'Planner',
        'icon': LucideIcons.calendar,
        'color': AppColors.accentBlue,
        'route': '/farm/planner',
      },
      {
        'label': 'Predictions',
        'icon': LucideIcons.target,
        'color': AppColors.accentPurple,
        'route': '/analytics/predictions',
      },
      {
        'label': 'P&L',
        'icon': LucideIcons.dollarSign,
        'color': AppColors.accentRed,
        'route': '/analytics/pnl',
      },
      {
        'label': 'Subsidy',
        'icon': LucideIcons.landmark,
        'color': AppColors.accentOrange,
        'route': '/farm/diary/subsidy',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final f = features[index];
        return AnimatedInteractiveCard(
          onTap: () => context.push(f['route'] as String),
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (f['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  f['icon'] as IconData,
                  color: f['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(f['label'] as String, style: AppTextStyles.label),
            ],
          ),
        );
      },
    );
  }
}
