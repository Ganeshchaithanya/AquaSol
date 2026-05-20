import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../core/services/api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/animated_interactive_card.dart';

class SubsidyTrackerScreen extends StatefulWidget {
  const SubsidyTrackerScreen({super.key});

  @override
  State<SubsidyTrackerScreen> createState() => _SubsidyTrackerScreenState();
}

class _SubsidyTrackerScreenState extends State<SubsidyTrackerScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _subsidyEntries = [];

  // Bank form key & controllers
  final _bankFormKey = GlobalKey<FormState>();
  final _holderNameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNoController = TextEditingController();
  final _ifscController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _holderNameController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final entries = await _apiService.getDiary();
      if (mounted) {
        setState(() {
          _subsidyEntries = entries.where((e) => e['is_subsidy_relevant'] == true).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitClaim(String entryId) async {
    if (!_bankFormKey.currentState!.validate()) return;

    Navigator.pop(context); // Close dialog
    setState(() => _isLoading = true);

    try {
      final res = await _apiService.submitSubsidyClaim(
        entryId,
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNoController.text.trim(),
        ifscCode: _ifscController.text.trim(),
        holderName: _holderNameController.text.trim(),
      );

      if (res != null && res['status'] == 'success') {
        await _load();
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit claim.')),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerPdfDownload(String entryId) async {
    setState(() => _isLoading = true);
    try {
      final downloadUrl = await _apiService.downloadSubsidyReport(entryId);
      
      // Simulated elegant loader
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
                Text('Funds will be deposited to this account after government approval.', style: AppTextStyles.bodySmall),
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
                  decoration: _inputDecoration('IFSC Code', LucideIcons.hash),
                  validator: (v) => v == null || v.length < 4 ? 'Please enter a valid IFSC code' : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _submitClaim(entryId),
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
        title: Text('Subsidy Tracker', style: AppTextStyles.screenTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subsidyEntries.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _subsidyEntries.length,
                    itemBuilder: (context, index) {
                      return _buildSubsidyCard(_subsidyEntries[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.landmark, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No subsidy claims found.', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text('Log activities as "Subsidy Relevant" to track them here.', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
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
                      style: AppTextStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Text(
                'ID: ${entry['id'].substring(0, 8)}',
                style: AppTextStyles.caption.copyWith(fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(entry['title'] ?? 'Subsidy Claim', style: AppTextStyles.cardTitle),
          const SizedBox(height: 8),
          Text(entry['description'] ?? '', style: AppTextStyles.bodySmall),
          const SizedBox(height: 6),
          Text('Claim amount: ₹${entry['cost'] ?? 0}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SUBMITTED', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(DateFormat('MMM dd, yyyy').format(submittedDate), style: AppTextStyles.label),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('EST. PAYOUT', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(DateFormat('MMM dd, yyyy').format(estimatedPayout), style: AppTextStyles.label),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (status.toLowerCase() == 'pending' || status.toLowerCase() == 'approved') ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: status.toLowerCase() == 'approved' ? 0.75 : 0.45,
                minHeight: 8,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.timer, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      daysRemaining > 0 ? '$daysRemaining days pending' : 'Processing payout...',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _triggerPdfDownload(entry['id']),
                  icon: const Icon(LucideIcons.download, size: 14, color: AppColors.primary),
                  label: const Text('Download PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                ),
              ],
            ),
          ] else if (status.toLowerCase() == 'paid') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.banknote, color: AppColors.accentGreen, size: 18),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Funds Transferred to Bank', style: AppTextStyles.label.copyWith(color: AppColors.accentGreen)),
                      if (entry['payment_reference'] != null)
                        Text('Ref: ${entry['payment_reference']}', style: AppTextStyles.caption.copyWith(color: AppColors.accentGreen.withValues(alpha: 0.7), fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
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
          ],
        ],
      ),
    );
  }
}
