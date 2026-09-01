import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/report_model.dart';

class ReportModal extends StatefulWidget {
  final String type; // 'store', 'product_before_order', 'product_after_order'
  final String targetId;
  final String targetName;
  final String storeId;
  final String? orderId;

  const ReportModal({
    super.key,
    required this.type,
    required this.targetId,
    required this.targetName,
    required this.storeId,
    this.orderId,
  });

  static void show(
    BuildContext context, {
    required String type,
    required String targetId,
    required String targetName,
    required String storeId,
    String? orderId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportModal(
        type: type,
        targetId: targetId,
        targetName: targetName,
        storeId: storeId,
        orderId: orderId,
      ),
    );
  }

  @override
  State<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal> {
  String? _selectedReason;
  final TextEditingController _commentsController = TextEditingController();
  bool _isSubmitting = false;

  List<String> get _reasons {
    switch (widget.type) {
      case 'store':
        return [
          'Unhygienic kitchen / food safety violation',
          'Fraudulent store / fake identity',
          'Inappropriate contact / harassment',
          'Off-platform payment requests',
          'Other',
        ];
      case 'product_before_order':
        return [
          'Inappropriate or misleading image',
          'Misleading product name or description',
          'Counterfeit or unauthorized item',
          'Prohibited / unsafe homemade item',
          'Other',
        ];
      case 'product_after_order':
      default:
        return [
          'Stale or spoiled quality',
          'Foreign object / unhygienic preparation',
          'Missing items / incorrect quantity',
          'Did not match product photos',
          'Other',
        ];
    }
  }

  String get _title {
    switch (widget.type) {
      case 'store':
        return 'Report Store';
      case 'product_before_order':
        return 'Report Product';
      case 'product_after_order':
      default:
        return 'Report Order Issue';
    }
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason for reporting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final docRef = FirebaseFirestore.instance.collection('reports').doc();

      final report = ReportModel(
        reportId: docRef.id,
        type: widget.type,
        targetId: widget.targetId,
        targetName: widget.targetName,
        storeId: widget.storeId,
        reporterUserId: user?.uid ?? 'anonymous',
        reporterName: user?.displayName ?? user?.phoneNumber ?? 'Customer',
        reason: _selectedReason!,
        comments: _commentsController.text.trim(),
        orderId: widget.orderId,
        status: 'open',
        createdAt: DateTime.now(),
      );

      await docRef.set(report.toMap());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Report submitted successfully. Our Trust & Safety team will review it within 24 hours.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                'Reporting: ${widget.targetName}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Why are you reporting this?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // Reason Radio List
              ..._reasons.map(
                (reason) => RadioListTile<String>(
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (val) => setState(() => _selectedReason = val),
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.red,
                  dense: true,
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Additional Comments (Optional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Provide extra details about the issue...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitReport,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
