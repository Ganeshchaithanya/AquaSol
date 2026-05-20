import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _waterUsage;
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Water', 'Moisture', 'Temp', 'Humidity'];
  List<dynamic> _zones = [];
  String? _selectedZoneId;
  List<dynamic> _history = [];
  
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    _zones = await apiService.getZones();
    _waterUsage = await apiService.getWaterUsage();
    
    if (_zones.isNotEmpty) {
      _selectedZoneId ??= _zones[0]['zone_id'].toString();
      _history = await apiService.getSensorHistory(zoneId: _selectedZoneId!);
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
  final List<IconData> _tabIcons = [
    LucideIcons.droplet,
    LucideIcons.sprout,
    LucideIcons.thermometer,
    LucideIcons.wind,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Analytics', style: AppTextStyles.screenTitle.copyWith(fontSize: 32)),
              Text('Last 7 days · Live readings', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 24),
              _buildTabs(),
              const SizedBox(height: 16),
              if (_zones.isNotEmpty) _buildZoneSelector(),
              const SizedBox(height: 24),
              _buildMainChartCard(),
              const SizedBox(height: 32),
              _buildRecentReadingsTable(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoneSelector() {
    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _zones.length,
        itemBuilder: (context, index) {
          final zone = _zones[index];
          bool isSel = _selectedZoneId == zone['zone_id'].toString();
          return GestureDetector(
            onTap: () {
              setState(() => _selectedZoneId = zone['zone_id'].toString());
              _load();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSel ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
              ),
              child: Center(
                child: Text(
                  zone['name'],
                  style: AppTextStyles.caption.copyWith(
                    color: isSel ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? _getTabColor(index) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isSelected ? _getTabColor(index) : AppColors.border),
                  boxShadow: isSelected
                      ? [BoxShadow(color: _getTabColor(index).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      _tabIcons[index],
                      size: 18,
                      color: isSelected ? Colors.white : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _tabs[index],
                      style: AppTextStyles.label.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Color _getTabColor(int index) {
    switch (index) {
      case 0: return AppColors.primary;
      case 1: return AppColors.accentGreen;
      case 2: return AppColors.accentOrange;
      case 3: return AppColors.accentBlue;
      default: return AppColors.primary;
    }
  }

  Widget _buildMainChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTabColor(_selectedTabIndex).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_tabIcons[_selectedTabIndex], color: _getTabColor(_selectedTabIndex), size: 16),
              ),
              const SizedBox(width: 12),
              Text(_tabs[_selectedTabIndex].toUpperCase(), style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const Spacer(),
              _buildTrendBadge('-14%', false),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _selectedTabIndex == 0 
                    ? (_waterUsage?['water_used_liters']?.toString() ?? '0') 
                    : _getLastReadingValue(), 
                style: AppTextStyles.dataValue.copyWith(fontSize: 40)
              ),
              const SizedBox(width: 8),
              Text(_selectedTabIndex == 0 ? 'L' : _getUnit(), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
            ],
          ),
          Text(
            _selectedTabIndex == 0 
                ? 'Avg across ${_zones.length} zones' 
                : (_history.isEmpty 
                    ? 'Waiting for device pairing...' 
                    : 'Current reading for ${_getSelectedZoneName()}${_getSelectedNodeInfo()}'), 
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)
          ),
          const SizedBox(height: 32),
          _buildLinkedHardwareSection(),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: _history.isEmpty 
                ? _buildEmptyDataState()
                : (_selectedTabIndex == 0 ? _buildBarChart() : _buildLineChart()),
          ),
          const SizedBox(height: 24),
          _buildChartLabels(),
        ],
      ),
    );
  }

  Widget _buildTrendBadge(String value, bool isPositive) {
    final color = isPositive ? AppColors.accentGreen : AppColors.accentOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 12, color: color),
          const SizedBox(width: 4),
          Text(value, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChartLabels() {
    if (_zones.isEmpty) return const SizedBox.shrink();
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _zones.asMap().entries.map((e) {
          final zone = e.value;
          bool isSelected = _selectedZoneId == zone['zone_id'].toString();
          Color color = isSelected ? _getTabColor(_selectedTabIndex) : AppColors.textMuted.withValues(alpha: 0.3);
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildChartLegend(zone['name'] ?? 'Zone', color),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildEmptyDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.barChart, size: 48, color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No Data Available',
            style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
          ),
          Text(
            'Pair your nodes to see live analytics',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    // Distribute total water usage across 7 days for visualization
    final double totalWater = (_waterUsage?['water_used_liters'] ?? 15418).toDouble();
    final List<double> dailyMock = [
      totalWater * 0.12, 
      totalWater * 0.15, 
      totalWater * 0.18, 
      totalWater * 0.10, 
      totalWater * 0.14, 
      totalWater * 0.16, 
      totalWater * 0.15
    ];

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (val >= 0 && val < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(days[val.toInt()], style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: dailyMock[i],
                color: AppColors.primary.withValues(alpha: 0.8),
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                gradient: LinearGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.6), AppColors.primary],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLineChart() {
    final List<FlSpot> spots = _getSpots();
    final Color mainColor = _getTabColor(_selectedTabIndex);

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                if (_history.isEmpty) return const Text('');
                // Show 5 intervals
                final step = (_history.length / 5).floor().clamp(1, 100);
                if (val.toInt() % step == 0 && val.toInt() < _history.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text('${val.toInt()}h', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => AppColors.primaryDark,
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem('${s.y.toStringAsFixed(1)}${_getUnit()}', AppTextStyles.bodySmall.copyWith(color: Colors.white))).toList(),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: mainColor,
            barWidth: 4,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true, 
              gradient: LinearGradient(
                colors: [mainColor.withValues(alpha: 0.2), mainColor.withValues(alpha: 0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Add a subtle target/average line for better aesthetics
          LineChartBarData(
            spots: spots.map((s) => FlSpot(s.x, s.y * 0.9 + 5)).toList(),
            isCurved: true,
            color: mainColor.withValues(alpha: 0.1),
            barWidth: 2,
            dashArray: [5, 5],
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getSpots() {
    if (_history.isEmpty) return [];
    return List.generate(_history.length, (i) {
      final entry = _history[i];
      double val = 0;
      switch (_selectedTabIndex) {
        case 1: val = (entry['soil_moisture'] ?? 0).toDouble(); break;
        case 2: val = (entry['temperature'] ?? 0).toDouble(); break;
        case 3: val = (entry['humidity'] ?? 0).toDouble(); break;
        default: val = 0;
      }
      return FlSpot(i.toDouble(), val);
    });
  }



  Widget _buildRecentReadingsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent ${_tabs[_selectedTabIndex]} readings', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                Text('6 entries', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
              ],
            ),
            Row(
              children: [
                _buildActionIconButton(LucideIcons.download),
                const SizedBox(width: 12),
                _buildActionIconButton(LucideIcons.chevronRight, isCircle: true, color: AppColors.primary.withValues(alpha: 0.1), iconColor: AppColors.primary),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildTableHeader(),
        if (_zones.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text('No zones found for this farm.', style: AppTextStyles.bodySmall),
          ))
        else
          ..._zones.map((zone) {
            final moisture = zone['current_moisture']?.toString() ?? '0';
            final status = (zone['current_moisture'] != null && zone['current_moisture'] < 50) ? 'Low' : 'Normal';
            return _buildTableRow(
              zone['name'] ?? 'Unknown', 
              '$moisture${_getUnit()}', 
              status, 
              'Live'
            );
          }),
      ],
    );
  }

  Widget _buildActionIconButton(IconData icon, {bool isCircle = false, Color? color, Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(12),
        border: color == null ? Border.all(color: AppColors.border) : null,
      ),
      child: Icon(icon, size: 18, color: iconColor ?? AppColors.textMuted),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('ZONE', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('VALUE', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('STATUS', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('TIME', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTableRow(String zone, String value, String status, String time) {
    final statusColor = status == 'Normal' ? AppColors.accentGreen : (status == 'Warning' ? AppColors.accentOrange : AppColors.accentRed);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.accentBlue, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Text(zone, style: AppTextStyles.label.copyWith(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(value, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(status, style: AppTextStyles.bodySmall.copyWith(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(time, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10))),
        ],
      ),
    );
  }
  String _getLastReadingValue() {
    if (_history.isEmpty) return '--';
    final last = _history.last;
    switch (_selectedTabIndex) {
      case 1: return last['soil_moisture']?.toStringAsFixed(0) ?? '--';
      case 2: return last['temperature']?.toStringAsFixed(1) ?? '--';
      case 3: return last['humidity']?.toStringAsFixed(0) ?? '--';
      default: return '--';
    }
  }

  String _getUnit() {
    switch (_selectedTabIndex) {
      case 1: return '%';
      case 2: return '°C';
      case 3: return '%';
      default: return '';
    }
  }

  String _getSelectedZoneName() {
    final zone = _zones.firstWhere((z) => z['zone_id'].toString() == _selectedZoneId, orElse: () => null);
    return zone?['name'] ?? 'Zone';
  }

  String _getSelectedNodeInfo() {
    final zone = _zones.firstWhere((z) => z['zone_id'].toString() == _selectedZoneId, orElse: () => null);
    if (zone != null && zone['node_mac'] != null) {
      return ' (Node: ${zone['node_mac']})';
    }
    return '';
  }

  Widget _buildLinkedHardwareSection() {
    final zone = _zones.firstWhere((z) => z['zone_id'].toString() == _selectedZoneId, orElse: () => null);
    if (zone == null || zone['nodes'] == null || (zone['nodes'] as List).isEmpty) {
      return const SizedBox.shrink();
    }

    final nodes = zone['nodes'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Linked Hardware', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: nodes.map((node) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.cpu, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    node['mac_address'] ?? 'Unknown Node',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
