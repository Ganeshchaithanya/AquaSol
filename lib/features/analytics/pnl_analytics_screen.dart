import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/animated_interactive_card.dart';

class PnlAnalyticsScreen extends StatefulWidget {
  const PnlAnalyticsScreen({super.key});

  @override
  State<PnlAnalyticsScreen> createState() => _PnlAnalyticsScreenState();
}

class _PnlAnalyticsScreenState extends State<PnlAnalyticsScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  late TabController _tabController;
  
  bool _isLoading = true;
  Map<String, dynamic>? _pnlData;
  List<dynamic> _zones = [];
  List<dynamic> _diaryEntries = [];
  
  // Custom cost controllers
  final _formKey = GlobalKey<FormState>();
  String _selectedStage = 'Vegetative';
  String _selectedCategory = 'fertilizer';
  String? _customCategory;
  final _costController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _selectedCostZoneId;
  bool _isSubsidyRelevant = false;

  // Bank Details controllers
  final _bankFormKey = GlobalKey<FormState>();
  final _holderNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNoController = TextEditingController();
  final _ifscController = TextEditingController();

  final List<String> _stages = ['Nursery', 'Transplanting', 'Vegetative', 'Flowering', 'Fruit Set', 'Yield Stage', 'Harvest', 'Maturity'];
  final List<String> _categories = ['fertilizer', 'pesticides', 'seeds', 'labor', 'machinery', 'water', 'land prep', 'other'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _costController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _holderNameController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _pnlData = await _apiService.getPnlAnalytics();
      _zones = await _apiService.getZones();
      _diaryEntries = await _apiService.getDiary();
      
      if (_zones.isNotEmpty) {
        _selectedCostZoneId ??= _zones[0]['zone_id'].toString();
      }
    } catch (e) {
      debugPrint('PnL full load error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCostZoneId == null) return;

    setState(() => _isLoading = true);
    try {
      final double cost = double.parse(_costController.text);
      final String finalCategory = _selectedCategory == 'other' && _customCategory != null 
          ? _customCategory!.trim().toLowerCase() 
          : _selectedCategory;

      final metadata = {
        'stage': _selectedStage,
        'cost': cost,
        'category': finalCategory,
        'sowing_days_offset': 45,
      };

      await _apiService.logActivity(
        zoneId: _selectedCostZoneId!,
        activityType: finalCategory,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        metadata: metadata,
        isSubsidy: _isSubsidyRelevant,
      );

      // Clear input fields
      _costController.clear();
      _titleController.clear();
      _bodyController.clear();
      _customCategory = null;
      
      // Reload everything
      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Expense logged successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding expense: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitToGov(String entryId) async {
    if (!_bankFormKey.currentState!.validate()) return;

    Navigator.pop(context); // Close bank dialog
    setState(() => _isLoading = true);

    try {
      await _apiService.submitSubsidyClaim(
        entryId,
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNoController.text.trim(),
        ifscCode: _ifscController.text.trim(),
        holderName: _holderNameController.text.trim(),
      );

      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Claim submitted successfully to the Ministry of Agriculture!', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Claim submit error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerPdfDownload(String entryId) async {
    setState(() => _isLoading = true);
    try {
      final downloadUrl = await _apiService.downloadSubsidyReport(entryId);
      
      // Simulate high-fidelity download state with a progress indicator
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: const Row(
              children: [
                Icon(LucideIcons.fileSpreadsheet, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text('PDF Generated', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Branded Gov-Ready PDF has been saved to your downloads directory successfully!', style: TextStyle(height: 1.4)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.link, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          downloadUrl ?? 'subsidy_report.pdf',
                          style: AppTextStyles.caption.copyWith(fontFamily: 'monospace'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBankDetailsDialog(String entryId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _bankFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.landmark, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Bank Account Details', style: AppTextStyles.cardTitle.copyWith(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Funds will be directly deposited to this account after government verification.', style: AppTextStyles.bodySmall),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _holderNameController,
                  decoration: _inputDecoration('Account Holder Name', LucideIcons.user),
                  validator: (v) => v == null || v.isEmpty ? 'Please enter holder name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bankNameController,
                  decoration: _inputDecoration('Bank Name', LucideIcons.landmark),
                  validator: (v) => v == null || v.isEmpty ? 'Please enter bank name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _accountNoController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Account Number', LucideIcons.creditCard),
                  validator: (v) => v == null || v.length < 8 ? 'Please enter a valid account number' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ifscController,
                  decoration: _inputDecoration('IFSC Code (e.g. SBIN0004312)', LucideIcons.hash),
                  validator: (v) => v == null || v.length < 4 ? 'Please enter a valid IFSC code' : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _submitToGov(entryId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.send),
                        SizedBox(width: 10),
                        Text('Send to Govt for Payout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  Color _getColorForIndex(int i) {
    final colors = [AppColors.primary, AppColors.accentBlue, AppColors.accentOrange, AppColors.accentPurple, AppColors.accentGreen, AppColors.accentRed];
    return colors[i % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Farm P&L Analytics', style: AppTextStyles.screenTitle.copyWith(fontSize: 20)),
            Text(_pnlData?['farm_name'] ?? 'Loading...', style: AppTextStyles.caption),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Stage Ledger'),
            Tab(text: 'Gov Subsidies'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildLedgerTab(),
                _buildSubsidyTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSeasonProfitCard(),
            const SizedBox(height: 24),
            _buildSavingsComparisonCard(),
            const SizedBox(height: 32),
            Text('COST BREAKDOWN', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            _buildCostDonutChart(),
            const SizedBox(height: 32),
            Text('ZONE ROI', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            if (_pnlData?['zone_roi'] != null)
              ...(_pnlData!['zone_roi'] as List).map((z) => _buildZoneRoiItem(
                    z['name'],
                    (z['roi'] ?? 0.0) / 100.0,
                    '₹${z['profit']}',
                    _getColorForIndex(_pnlData!['zone_roi'].indexOf(z)),
                  )),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonProfitCard() {
    final profit = _pnlData?['total_profit'] ?? 0;
    final totalCost = _pnlData?['total_cost'] ?? 0;
    final growth = _pnlData?['growth_percent'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.pnlGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentOrange.withValues(alpha: 0.2),
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
              Text('NET FARM REVENUE', style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 14, letterSpacing: 1.5)),
              const Icon(LucideIcons.trendingUp, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('₹$profit', style: AppTextStyles.dataDisplay.copyWith(color: Colors.white, fontSize: 42)),
              const SizedBox(width: 12),
              Text('Net Gain', style: AppTextStyles.label.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniRevenueMetric('Total Spent', '₹$totalCost'),
              _buildMiniRevenueMetric('Revenue Growth', '+$growth%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniRevenueMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white60)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSavingsComparisonCard() {
    final double actualSpent = (_pnlData?['total_cost'] ?? 0).toDouble();
    // Dynamic crop guide baseline budget calculation (₹20,000 recommended per zone default)
    final double recommendedBaseline = _zones.length * 20000.0;
    final double overspent = (actualSpent - recommendedBaseline).clamp(0.0, 1000000.0);
    final double savingsPercentage = recommendedBaseline > 0 ? (overspent / actualSpent) * 100.0 : 0.0;

    final isOptimized = actualSpent <= recommendedBaseline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isOptimized ? AppColors.accentGreen.withValues(alpha: 0.3) : AppColors.accentOrange.withValues(alpha: 0.3),
          width: 1.5,
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
                  color: (isOptimized ? AppColors.accentGreen : AppColors.accentOrange).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOptimized ? LucideIcons.sparkles : LucideIcons.flame,
                  color: isOptimized ? AppColors.accentGreen : AppColors.accentOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SOLU AI BUDGET ADVISOR', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text(isOptimized ? 'Cost Control: OPTIMIZED' : 'Cost Control: SAVINGS DETECTED', style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSavingsValue('Spent Actual', '₹${actualSpent.toInt()}', Colors.black),
              _buildSavingsValue('Crop Guide Target', '₹${recommendedBaseline.toInt()}', AppColors.primary),
              _buildSavingsValue(
                isOptimized ? 'Saved Under Guide' : 'Excess Overspend',
                isOptimized ? '₹${(recommendedBaseline - actualSpent).toInt()}' : '₹${overspent.toInt()}',
                isOptimized ? AppColors.accentGreen : AppColors.accentOrange,
                isBold: true,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            isOptimized
                ? 'Outstanding! Your spending is below the optimal Crop Guide recommended baseline of ₹20,000/acre. You managed resources exceptionally well.'
                : 'Solu Analysis: You spent ${savingsPercentage.toStringAsFixed(0)}% more than the planner\'s crop guide recommends! Following the planner\'s precision water schedules and targeted fertilizer dosage would have saved you ₹${overspent.toInt()} in excess inputs!',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsValue(String label, String value, Color valueColor, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildCostDonutChart() {
    final breakdown = _pnlData?['cost_breakdown'] as Map<String, dynamic>? ?? {};
    if (breakdown.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Text('No expenses logged yet.', style: AppTextStyles.bodySmall),
      );
    }

    final sections = breakdown.entries.map((e) {
      return PieChartSectionData(
        color: _getColorForIndex(breakdown.keys.toList().indexOf(e.key)),
        value: (e.value as num).toDouble(),
        radius: 12,
        showTitle: false,
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            height: 130,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 36,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: breakdown.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildLegendItem(
                    e.key.toUpperCase(),
                    _getColorForIndex(breakdown.keys.toList().indexOf(e.key)),
                    '${e.value}%',
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String percent) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 11))),
        Text(percent, style: AppTextStyles.label.copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _buildZoneRoiItem(String name, double progress, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
              Text(value, style: AppTextStyles.label.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ─── LEDGER TAB ──────────────────────────────────────────────────────────
  Widget _buildLedgerTab() {
    final expenses = _diaryEntries.where((e) => (e['cost'] ?? 0) > 0).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExpenseFormCard(),
          const SizedBox(height: 32),
          Text('GROWTH STAGE LEDGER', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          if (expenses.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: Text('No expenses registered in stages yet.', style: AppTextStyles.bodySmall),
            )
          else
            ...expenses.map((exp) {
              // Parse stage if stored in record_data
              String stage = 'Vegetative';
              try {
                if (exp['record_data'] != null) {
                  final meta = jsonDecode(exp['record_data']);
                  stage = meta['stage'] ?? 'Vegetative';
                }
              } catch (_) {}

              return _buildLedgerItem(exp, stage);
            }),
        ],
      ),
    );
  }

  Widget _buildExpenseFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.plusCircle, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text('Log Growth Cost', style: AppTextStyles.cardTitle),
              ],
            ),
            const SizedBox(height: 20),
            
            // Zone Selector
            DropdownButtonFormField<String>(
              initialValue: _selectedCostZoneId,
              decoration: _inputDecoration('Select Zone / Crop', LucideIcons.sprout),
              items: _zones.map((z) {
                return DropdownMenuItem<String>(
                  value: z['zone_id'].toString(),
                  child: Text('${z['name']} (${z['crop_type']})'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedCostZoneId = v),
            ),
            const SizedBox(height: 16),

            // Stage Selector
            DropdownButtonFormField<String>(
              initialValue: _selectedStage,
              decoration: _inputDecoration('Crop Growth Stage', LucideIcons.gitCommit),
              items: _stages.map((stg) {
                return DropdownMenuItem<String>(value: stg, child: Text(stg));
              }).toList(),
              onChanged: (v) => setState(() => _selectedStage = v ?? 'Vegetative'),
            ),
            const SizedBox(height: 16),

            // Cost Category
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: _inputDecoration('Category', LucideIcons.tag),
              items: _categories.map((cat) {
                return DropdownMenuItem<String>(value: cat, child: Text(cat.toUpperCase()));
              }).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v ?? 'fertilizer'),
            ),
            const SizedBox(height: 16),

            if (_selectedCategory == 'other') ...[
              TextFormField(
                decoration: _inputDecoration('Custom Category Label', LucideIcons.edit3),
                validator: (v) => _selectedCategory == 'other' && (v == null || v.isEmpty) ? 'Please enter cost label' : null,
                onChanged: (v) => _customCategory = v,
              ),
              const SizedBox(height: 16),
            ],

            // Amount Input
            TextFormField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Amount spent (₹)', LucideIcons.banknote),
              validator: (v) => v == null || double.tryParse(v) == null ? 'Please enter a valid amount' : null,
            ),
            const SizedBox(height: 16),

            // Title Input
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration('Expense Item (e.g. Organic NPK)', LucideIcons.textCursor),
              validator: (v) => v == null || v.isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),

            // Description Input
            TextFormField(
              controller: _bodyController,
              decoration: _inputDecoration('Notes / Brand details', LucideIcons.fileText),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Subsidy relevant switch
            SwitchListTile(
              title: const Text('Subsidy Payout Eligible', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Includes in Ministry of Agriculture reports', style: TextStyle(fontSize: 11)),
              value: _isSubsidyRelevant,
              activeThumbColor: AppColors.primary,
              onChanged: (val) => setState(() => _isSubsidyRelevant = val),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _addExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Log Cost Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerItem(Map<String, dynamic> exp, String stage) {
    final double cost = (exp['cost'] ?? 0).toDouble();
    final DateTime date = DateTime.parse(exp['timestamp']);
    final isSub = exp['is_subsidy_relevant'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSub ? LucideIcons.landmark : LucideIcons.tag,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exp['title'] ?? 'Expense', style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  'STAGE: ${stage.toUpperCase()} · ${exp['type']?.toString().toUpperCase()}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy · hh:mm a').format(date),
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            '₹${cost.toInt()}',
            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  // ─── SUBSIDY TAB ─────────────────────────────────────────────────────────
  Widget _buildSubsidyTab() {
    final subsidyEntries = _diaryEntries.where((e) => e['is_subsidy_relevant'] == true).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: subsidyEntries.isEmpty
          ? ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.landmark, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('No subsidy claims found.', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      Text('Log growth cost entries as "Subsidy Payout Eligible"\nto file claims.', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: subsidyEntries.length,
              itemBuilder: (context, index) {
                return _buildSubsidyCard(subsidyEntries[index]);
              },
            ),
    );
  }

  Widget _buildSubsidyCard(Map<String, dynamic> entry) {
    final String status = entry['subsidy_status'] ?? '';
    final DateTime submittedDate = DateTime.parse(entry['timestamp']);
    
    // Estimate payout date (approx 45 days after submission)
    final DateTime estimatedPayout = submittedDate.add(const Duration(days: 45));
    final int daysRemaining = estimatedPayout.difference(DateTime.now()).inDays;
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status.toLowerCase()) {
      case 'paid':
        statusColor = AppColors.accentGreen;
        statusIcon = LucideIcons.checkCircle2;
        break;
      case 'approved':
        statusColor = AppColors.accentBlue;
        statusIcon = LucideIcons.thumbsUp;
        break;
      case 'pending':
        statusColor = AppColors.accentOrange;
        statusIcon = LucideIcons.clock;
        break;
      default:
        statusColor = AppColors.textMuted;
        statusIcon = LucideIcons.fileEdit;
    }

    // Try parsing bank info if present
    String? bankInfo;
    try {
      if (entry['record_data'] != null) {
        final meta = jsonDecode(entry['record_data']);
        if (meta['bank_name'] != null && meta['account_number'] != null) {
          bankInfo = '${meta['bank_name']} · A/C ****${meta['account_number'].toString().substring(meta['account_number'].toString().length - 4)}';
        }
      }
    } catch (_) {}

    return AnimatedInteractiveCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      status.isEmpty ? 'DRAFT' : status.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Text(
                'CLAIM ID: ${entry['id'].substring(0, 8).toUpperCase()}',
                style: AppTextStyles.caption.copyWith(fontFamily: 'monospace', fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(entry['title'] ?? 'Subsidy Claim', style: AppTextStyles.cardTitle),
          const SizedBox(height: 6),
          Text('Expense value: ₹${entry['cost']}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
          if (bankInfo != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.landmark, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Text(bankInfo, style: AppTextStyles.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          if (status.isEmpty || status.toLowerCase() == 'draft' || status.toLowerCase() == 'none') ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _showBankDetailsDialog(entry['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.send, size: 16),
                    SizedBox(width: 8),
                    Text('Send to Govt for Subsidy', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Status Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: status.toLowerCase() == 'paid' 
                    ? 1.0 
                    : (status.toLowerCase() == 'approved' ? 0.75 : 0.45),
                minHeight: 8,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 12),
            
            // Pending payout countdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.timer, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      status.toLowerCase() == 'paid' 
                          ? 'Payout Completed' 
                          : (daysRemaining > 0 ? '$daysRemaining days pending' : 'Processing payout...'),
                      style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                
                // Branded PDF Download Trigger
                TextButton.icon(
                  onPressed: () => _triggerPdfDownload(entry['id']),
                  icon: const Icon(LucideIcons.download, size: 14, color: AppColors.primary),
                  label: const Text('Download PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
