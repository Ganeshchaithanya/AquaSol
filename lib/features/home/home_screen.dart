import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../core/services/language_provider.dart';
import '../../core/services/notification_service.dart';
import '../../shared/widgets/animated_interactive_card.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/update_service.dart';
import '../../shared/widgets/app_drawer.dart';

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
  Map<String, dynamic>? _user;
  Timer? _pollingTimer;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _load();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) _silentPoll();
    });
  }

  Future<void> _silentPoll() async {
    try {
      final data = await _apiService.getDashboard();
      if (mounted && data != null) {
        setState(() {
          _dashboard = data;
          _lastUpdated = DateTime.now();
        });
        _checkThresholdsAndAlerts();
      }
    } catch (e) {
      debugPrint('Silent poll error: $e');
    }
  }

  Future<void> _checkThresholdsAndAlerts() async {
    if (_dashboard == null) return;

    final zones = _dashboard?['zones'] as List?;
    if (zones != null) {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      for (final zone in zones) {
        final nodes = zone['nodes'] as List?;
        if (nodes == null) continue;

        for (final node in nodes) {
          final nodeLabel = node['node_label']?.toString() ?? 'Node';
          final nodeStatus = node['status']?.toString() ?? 'offline';

          if (nodeStatus == 'offline') {
            final cooldownKey = 'last_offline_notif_${node['mac_address']}';
            final lastNotifiedStr = prefs.getString(cooldownKey);
            bool shouldNotify = true;
            if (lastNotifiedStr != null) {
              final lastNotified = DateTime.parse(lastNotifiedStr);
              if (now.difference(lastNotified).inMinutes < 60) {
                shouldNotify = false;
              }
            }
            if (shouldNotify) {
              await NotificationService.showNotification(
                id: nodeLabel.hashCode ^ 888,
                title: '📡 Node Offline: $nodeLabel',
                body: '$nodeLabel has gone offline. Check power and RF connection.',
                channelId: 'sensor_alerts',
                channelName: 'Sensor Alerts',
              );
              await prefs.setString(cooldownKey, now.toIso8601String());
            }
          }
        }

        final zoneId = zone['zone_id']?.toString() ?? '';
        final zoneName = zone['name']?.toString() ?? 'Zone';
        final currentMoisture = zone['current_moisture'] != null
            ? (zone['current_moisture'] as num).toDouble()
            : null;
        final minMoisture = zone['target_moisture_min'] != null
            ? (zone['target_moisture_min'] as num).toDouble()
            : 40.0;

        if (currentMoisture != null && currentMoisture < minMoisture) {
          final lastNotifiedStr = prefs.getString('last_moisture_alert_$zoneId');
          bool shouldNotify = true;
          if (lastNotifiedStr != null) {
            final lastNotified = DateTime.parse(lastNotifiedStr);
            if (now.difference(lastNotified).inMinutes < 60) {
              shouldNotify = false;
            }
          }
          if (shouldNotify) {
            await NotificationService.showNotification(
              id: zoneId.hashCode ^ 999,
              title: '💧 Low Soil Moisture: $zoneName',
              body: 'Soil moisture in $zoneName is at ${currentMoisture.toStringAsFixed(1)}%, below your minimum of ${minMoisture.toStringAsFixed(1)}%.',
              channelId: 'sensor_alerts',
              channelName: 'Sensor Alerts',
            );
            await prefs.setString('last_moisture_alert_$zoneId', now.toIso8601String());
          }
        }
      }
    }

    try {
      final recentAlerts = await _apiService.getAlerts();
      if (recentAlerts.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final notifiedAlerts = prefs.getStringList('notified_backend_alerts') ?? [];
        final List<String> newNotifiedAlerts = List.from(notifiedAlerts);
        int notificationCount = 0;

        for (final alert in recentAlerts) {
          final alertId = alert['id']?.toString() ?? '';
          if (alertId.isNotEmpty && !notifiedAlerts.contains(alertId)) {
            final title = alert['title'] ?? 'System Update';
            final desc = alert['description'] ?? 'An event occurred in the irrigation system.';
            await NotificationService.showNotification(
              id: alertId.hashCode,
              title: title,
              body: desc,
              channelId: 'system_alerts',
              channelName: 'System Alerts',
              channelDescription: 'Alerts triggered by backend system events',
            );
            newNotifiedAlerts.add(alertId);
            notificationCount++;
            if (notificationCount >= 3) break;
          }
        }

        if (notificationCount > 0) {
          if (newNotifiedAlerts.length > 100) {
            newNotifiedAlerts.removeRange(0, newNotifiedAlerts.length - 100);
          }
          await prefs.setStringList('notified_backend_alerts', newNotifiedAlerts);
        }
      }
    } catch (e) {
      debugPrint('Error checking backend alerts: $e');
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final data = await _apiService.getDashboard();
      Map<String, dynamic>? userData;
      try {
        userData = await _apiService.getMe();
      } catch (e) {
        debugPrint('Home profile load error: $e');
      }
      if (mounted) {
        setState(() {
          _dashboard = data;
          _user = userData;
          _hasError = false;
          _lastUpdated = DateTime.now();
        });
        _checkThresholdsAndAlerts();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) UpdateService.checkForUpdates(context);
        });
      }
    } catch (e) {
      debugPrint('Home load error: $e');
      final isAuthError = e.toString().contains('401') ||
          e.toString().contains('403') ||
          e.toString().contains('Unauthorized');
      if (isAuthError) {
        await _apiService.logout();
        if (mounted) {
          context.go('/login');
          return;
        }
      }
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLanguageSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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

  Widget _buildLangOption(
      BuildContext context, String code, String label, String native) {
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
          Text(native,
              style: AppTextStyles.label.copyWith(
                  color: isSel ? AppColors.primary : AppColors.textPrimary)),
          const Spacer(),
          if (isSel)
            const Icon(LucideIcons.checkCircle2,
                color: AppColors.primary, size: 20),
        ],
      ),
    );
  }

  int get _offlineNodeCount {
    int count = 0;
    final zones = _dashboard?['zones'] as List?;
    if (zones == null) return 0;
    for (final zone in zones) {
      final nodes = zone['nodes'] as List?;
      if (nodes == null) continue;
      for (final node in nodes) {
        if (node['status']?.toString() == 'offline') count++;
      }
    }
    return count;
  }

  String _formatLastSeen(String? lastSeenIso) {
    if (lastSeenIso == null) return 'Never';
    try {
      final dt = DateTime.parse(lastSeenIso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '--';
    }
  }

  String _formatLastUpdated() {
    if (_lastUpdated == null) return '';
    final diff = DateTime.now().difference(_lastUpdated!);
    if (diff.inSeconds < 5) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) return _buildConnectionErrorState();
    if (_dashboard == null) return _buildNoFarmState();

    final totalAlerts = _dashboard?['total_alerts'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      body: Builder(
        builder: (ctx) => SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildInBodyHeader(ctx, l10n, totalAlerts),
                  const SizedBox(height: 20),
                  _buildGreeting(l10n),
                  if (_offlineNodeCount > 0) ...[
                    const SizedBox(height: 12),
                    _buildOfflineBanner(),
                  ],
                  const SizedBox(height: 20),
                  _buildHealthHero(),
                  const SizedBox(height: 16),
                  _buildMasterCard(),
                  const SizedBox(height: 20),
                  _buildNodesSection(),
                  const SizedBox(height: 20),
                  _buildMetricsGrid(totalAlerts),
                  const SizedBox(height: 20),
                  _buildAIAdvisory(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                  const SizedBox(height: 28),
                  Text('More Features', style: AppTextStyles.sectionLabel),
                  const SizedBox(height: 14),
                  _buildExtendedFeaturesGrid(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInBodyHeader(
      BuildContext ctx, AppLocalizations l10n, int totalAlerts) {
    return Row(
      children: [
        Builder(
          builder: (drawerCtx) => GestureDetector(
            onTap: () => Scaffold.of(drawerCtx).openDrawer(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(LucideIcons.menu,
                  color: AppColors.primary, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(LucideIcons.droplets,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Text('AquaSol',
            style: AppTextStyles.screenTitle.copyWith(fontSize: 20)),
        const Spacer(),
        IconButton(
          onPressed: () => _showLanguageSelector(context),
          icon: const Icon(LucideIcons.languages,
              color: AppColors.primary, size: 22),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => context.push('/alerts'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(LucideIcons.bell,
                    color: AppColors.primary, size: 20),
              ),
              if (totalAlerts > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.accentRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      totalAlerts > 99 ? '99+' : '$totalAlerts',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(_user?['avatar_url'] ??
                    'https://ui-avatars.com/api/?name=${_user?['name'] ?? 'Farmer'}&background=random'),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: AppColors.border, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.wifiOff,
              color: AppColors.accentRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$_offlineNodeCount node${_offlineNodeCount > 1 ? 's' : ''} offline — check RF connection & power',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.accentRed, fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/system-health'),
            child: const Icon(LucideIcons.chevronRight,
                color: AppColors.accentRed, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(AppLocalizations l10n) {
    final rawName = _user?['name'] ?? 'Farmer';
    final userName =
        rawName.contains("'") ? rawName.split("'")[0] : rawName;
    final temp = _dashboard?['weather']?['temperature'] ?? '--';
    final condition = _dashboard?['weather']?['condition'] ?? '--';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${l10n.greeting}, $userName 👋',
            style: AppTextStyles.screenTitle.copyWith(fontSize: 26)),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(LucideIcons.cloudSun,
                color: AppColors.textSecondary, size: 15),
            const SizedBox(width: 6),
            Text('$temp°C · $condition',
                style: AppTextStyles.bodySmall),
            const Spacer(),
            if (_lastUpdated != null)
              Row(
                children: [
                  const Icon(LucideIcons.refreshCw,
                      color: AppColors.textMuted, size: 12),
                  const SizedBox(width: 4),
                  Text(_formatLastUpdated(),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthHero() {
    final score = _dashboard?['metrics']?['health_score'];
    final displayScore = score?.toString() ?? '--';
    String status = 'Optimal';
    Color statusColor = const Color(0xFF6EE7B7);
    if (score != null && score < 60) {
      status = 'Critical';
      statusColor = const Color(0xFFFCA5A5);
    } else if (score != null && score < 85) {
      status = 'Caution';
      statusColor = const Color(0xFFFDE68A);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.healthGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Farm Health',
                    style: AppTextStyles.label.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(displayScore,
                        style: AppTextStyles.dataDisplay.copyWith(
                            color: Colors.white, fontSize: 56)),
                    Text('/100',
                        style: AppTextStyles.dataDisplay.copyWith(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 24)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(status,
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildHeroStat(
                    LucideIcons.droplets,
                    '${_dashboard?['metrics']?['water_used_today'] ?? '--'} L',
                    'Today',
                  ),
                  const SizedBox(height: 6),
                  _buildHeroStat(
                    LucideIcons.activity,
                    '${_dashboard?['active_zones'] ?? '--'}/${_dashboard?['total_zones'] ?? '--'}',
                    'Zones',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 14),
        const SizedBox(width: 5),
        Text('$value $label',
            style: AppTextStyles.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMasterCard() {
    final master = _dashboard?['master_status'];
    if (master == null) return const SizedBox.shrink();

    final rain = master['rain_detected'] ?? false;
    final flow = (master['flow_rate'] ?? 0.0).toDouble();
    final battery = (master['battery_pct'] ?? 0.0).toDouble();
    final solar = (master['solar_voltage'] ?? 0.0).toDouble();
    final solarPct = (master['solar_pct'] ?? 0.0).toDouble();
    final lastSeen = master['last_seen'] != null
        ? DateTime.parse(master['last_seen']).toLocal()
        : null;

    final isOnline = lastSeen != null &&
        DateTime.now().difference(lastSeen).inMinutes < 10;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOnline
              ? AppColors.accentGreen.withValues(alpha: 0.3)
              : AppColors.accentRed.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isOnline ? AppColors.accentGreen : AppColors.accentRed)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(LucideIcons.router,
                    color: isOnline
                        ? AppColors.accentGreen
                        : AppColors.accentRed,
                    size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Master Gateway',
                        style: AppTextStyles.label
                            .copyWith(fontWeight: FontWeight.bold)),
                    Text(master['mac_address']?.toString() ?? '--',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isOnline ? AppColors.accentGreen : AppColors.accentRed)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? AppColors.accentGreen
                            : AppColors.accentRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: AppTextStyles.caption.copyWith(
                        color: isOnline
                            ? AppColors.accentGreen
                            : AppColors.accentRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
              color: AppColors.border.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMasterMetric(
                battery > 20 ? LucideIcons.batteryFull : LucideIcons.batteryLow,
                '${battery.toStringAsFixed(0)}%',
                'Battery',
                battery > 20 ? AppColors.accentGreen : AppColors.accentRed,
              ),
              _buildMasterMetric(
                LucideIcons.sun,
                '${solar.toStringAsFixed(1)}V',
                'Solar (${solarPct.toStringAsFixed(0)}%)',
                AppColors.accentGold,
              ),
              _buildMasterMetric(
                LucideIcons.droplet,
                '${flow.toStringAsFixed(1)} L/m',
                'Flow Rate',
                AppColors.accentBlue,
              ),
              _buildMasterMetric(
                rain ? LucideIcons.cloudRain : LucideIcons.cloudOff,
                rain ? 'Yes' : 'None',
                'Rain',
                rain ? AppColors.accentBlue : AppColors.textMuted,
              ),
            ],
          ),
          if (lastSeen != null) ...[
            const SizedBox(height: 10),
            Text(
              'Last seen: ${_formatLastSeen(lastSeen.toUtc().toIso8601String())}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMasterMetric(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 5),
        Text(value,
            style: AppTextStyles.label
                .copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildNodesSection() {
    final zones = _dashboard?['zones'] as List?;
    if (zones == null || zones.isEmpty) return const SizedBox.shrink();

    final List<Map<String, dynamic>> allNodes = [];
    for (final zone in zones) {
      final nodes = zone['nodes'] as List?;
      if (nodes == null) continue;
      for (final node in nodes) {
        allNodes.add({
          ...Map<String, dynamic>.from(node as Map),
          'zone_name': zone['name']?.toString() ?? 'Zone',
          'zone_id': zone['zone_id']?.toString() ?? '',
          'zone_moisture': zone['current_moisture'],
          'valve_open': zone['valve_state'] == true,
        });
      }
    }

    if (allNodes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Field Nodes', style: AppTextStyles.sectionLabel),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${allNodes.length}',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allNodes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _buildNodeCard(allNodes[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildNodeCard(Map<String, dynamic> node) {
    final label = node['node_label']?.toString() ?? 'Node';
    final status = node['status']?.toString() ?? 'offline';
    final isOnline = status == 'online';
    final moisture = node['current_moisture'] != null
        ? (node['current_moisture'] as num).toDouble()
        : null;
    final battery = node['battery_pct'] != null
        ? (node['battery_pct'] as num).toDouble()
        : null;
    final valveOpen = node['valve_status'] == true;
    final lastSeen = node['last_seen']?.toString();
    final zoneName = node['zone_name']?.toString() ?? 'Zone';
    final isVirtual = node['is_virtual'] == true;

    final statusColor =
        isOnline ? AppColors.accentGreen : AppColors.accentRed;

    return GestureDetector(
      onTap: () {
        final zoneId = node['zone_id']?.toString() ?? '';
        if (zoneId.isNotEmpty) context.push('/farm/zone/$zoneId');
      },
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: AppTextStyles.label.copyWith(fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(zoneName,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textMuted, fontSize: 10),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOnline ? LucideIcons.wifi : LucideIcons.wifiOff,
                    color: statusColor,
                    size: 11,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isVirtual ? 'Virtual' : (isOnline ? 'Online' : 'Offline'),
                    style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (isOnline) ...[
              _buildNodeStat(LucideIcons.droplets,
                  moisture != null ? '${moisture.toStringAsFixed(1)}%' : '--',
                  AppColors.accentBlue),
              const SizedBox(height: 4),
              _buildNodeStat(
                  battery != null && battery > 20
                      ? LucideIcons.batteryFull
                      : LucideIcons.batteryLow,
                  battery != null
                      ? '${battery.toStringAsFixed(0)}%'
                      : '--',
                  battery != null && battery > 20
                      ? AppColors.accentGreen
                      : AppColors.accentRed),
              if (valveOpen) ...[
                const SizedBox(height: 4),
                _buildNodeStat(
                    LucideIcons.droplet, 'Valve Open', AppColors.accentBlue),
              ],
            ] else ...[
              Text(
                'Last: ${_formatLastSeen(lastSeen)}',
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNodeStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 5),
        Text(value,
            style: AppTextStyles.caption.copyWith(
                fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMetricsGrid(int totalAlerts) {
    final activeZones = _dashboard?['active_zones'];
    final totalZones = _dashboard?['total_zones'];
    final waterToday = _dashboard?['metrics']?['water_used_today'];
    final aiDecisions = _dashboard?['metrics']?['ai_decisions_count'];

    final metrics = [
      {
        'label': "Today's Water",
        'value': waterToday?.toString() ?? '--',
        'unit': 'L',
        'icon': LucideIcons.droplets,
        'color': AppColors.accentBlue,
      },
      {
        'label': 'Active Zones',
        'value': (activeZones != null && totalZones != null)
            ? '$activeZones/$totalZones'
            : '--',
        'unit': '',
        'icon': LucideIcons.activity,
        'color': AppColors.accentGreen,
      },
      {
        'label': 'AI Decisions',
        'value': aiDecisions?.toString() ?? '--',
        'unit': '',
        'icon': LucideIcons.sparkles,
        'color': AppColors.accentPurple,
      },
      {
        'label': 'Alerts',
        'value': totalAlerts > 0 ? '$totalAlerts' : '0',
        'unit': '',
        'icon': LucideIcons.shield,
        'color': totalAlerts > 0 ? AppColors.accentRed : AppColors.accentGreen,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.55,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final m = metrics[index];
        return _buildMetricCard(
          m['label'] as String,
          m['value'] as String,
          m['unit'] as String,
          m['icon'] as IconData,
          m['color'] as Color,
        );
      },
    );
  }

  Widget _buildMetricCard(
      String label, String value, String unit, IconData icon, Color color) {
    return AnimatedInteractiveCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value,
                      style: AppTextStyles.dataValue
                          .copyWith(fontSize: 24, color: AppColors.textPrimary)),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 3),
                    Text(unit,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ],
              ),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppColors.accentPurple.withValues(alpha: 0.15)),
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
                child: const Icon(LucideIcons.sparkles,
                    color: AppColors.accentPurple, size: 17),
              ),
              const SizedBox(width: 10),
              Text('AI Advisory',
                  style: AppTextStyles.label.copyWith(
                      color: AppColors.accentPurple, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            advisory != null
                ? (advisory['text'] ??
                    'System suggests no changes currently.')
                : 'Once your nodes report data, Solu will provide real-time irrigation advice here.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.primaryDark),
          ),
          if (advisory != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                _buildAdvisoryButton('Approve', AppColors.accentPurple, () async {
                  setState(() => _isLoading = true);
                  await _apiService.handleAdvisoryAction(
                      zoneId: advisory['zone_id'], action: 'approve');
                  _load();
                }),
                const SizedBox(width: 12),
                _buildAdvisoryButton('Dismiss', null, () async {
                  setState(() => _isLoading = true);
                  await _apiService.handleAdvisoryAction(
                      zoneId: advisory['zone_id'], action: 'dismiss');
                  _load();
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvisoryButton(
      String label, Color? bg, VoidCallback onTap) {
    final isFilled = bg != null;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isFilled ? bg.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.accentPurple.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(
                color: AppColors.accentPurple,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final actions = [
      {
        'label': 'Irrigate Now',
        'icon': LucideIcons.droplets,
        'color': AppColors.accentBlue,
        'route': '/control',
      },
      {
        'label': 'Diagnostic',
        'icon': LucideIcons.activity,
        'color': AppColors.accentGreen,
        'route': '/system-health',
      },
      {
        'label': 'Planner',
        'icon': LucideIcons.calendar,
        'color': AppColors.primary,
        'route': '/farm/planner',
      },
      {
        'label': 'Ask Solu',
        'icon': LucideIcons.messageCircle,
        'color': AppColors.accentPurple,
        'route': '/chatbot',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final a = actions[index];
        final color = a['color'] as Color;
        return GestureDetector(
          onTap: () => context.push(a['route'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(a['icon'] as IconData, color: color, size: 18),
                ),
                const SizedBox(height: 7),
                Text(
                  a['label'] as String,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                      fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExtendedFeaturesGrid() {
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
        'label': 'Growth Stage',
        'icon': LucideIcons.layoutGrid,
        'color': AppColors.accentGreen,
        'route': '/farm/stage/$firstZoneId',
      },
      {
        'label': 'Farm Diary',
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
      {
        'label': 'FAQ',
        'icon': LucideIcons.helpCircle,
        'color': AppColors.primary,
        'route': '/faq',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final f = features[index];
        final color = f['color'] as Color;
        return GestureDetector(
          onTap: () => context.push(f['route'] as String),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(f['icon'] as IconData, color: color, size: 16),
                ),
                const SizedBox(height: 7),
                Text(
                  f['label'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTextStyles.caption
                      .copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
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
                child: const Icon(LucideIcons.wifiOff,
                    size: 64, color: AppColors.accentRed),
              ),
              const SizedBox(height: 32),
              Text('Connection Error',
                  style: AppTextStyles.screenTitle,
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Can\'t reach the AquaSol server. Ensure backend is running and you\'re connected.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _load,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Retry Connection',
                      style: AppTextStyles.label.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
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
                child: const Icon(LucideIcons.sprout,
                    size: 64, color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              Text('Welcome to AquaSol',
                  style: AppTextStyles.screenTitle,
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'You haven\'t set up your farm yet. Connect your devices and configure your zones to start smart irrigation.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => context.go('/farm-setup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Setup My Farm',
                      style: AppTextStyles.label.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
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
}
