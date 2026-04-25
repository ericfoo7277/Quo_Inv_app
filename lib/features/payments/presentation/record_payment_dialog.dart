import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../shared/models/payment.dart';
import '../../../shared/providers/repository_providers.dart';

const _uuid = Uuid();

class RecordPaymentDialog extends ConsumerStatefulWidget {
  const RecordPaymentDialog({
    super.key,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.customerName,
    required this.maxAmount,
  });

  final String invoiceId;
  final String invoiceNumber;
  final String customerName;
  final double maxAmount;

  @override
  ConsumerState<RecordPaymentDialog> createState() =>
      _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends ConsumerState<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  final _notesCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  PaymentMethod _method = PaymentMethod.bank;
  bool _loading = false;

  final _dateFmt = DateFormat.yMMMd();

  @override
  void initState() {
    super.initState();
    _amountCtrl =
        TextEditingController(text: widget.maxAmount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final payment = Payment(
        id: _uuid.v4(),
        invoiceId: widget.invoiceId,
        invoiceNumber: widget.invoiceNumber,
        customerName: widget.customerName,
        amount: double.tryParse(_amountCtrl.text) ?? 0,
        date: _date,
        method: _method,
      );
      await ref.read(paymentRepositoryProvider).create(payment);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(borderRadius: AppRadius.sheet),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Record Payment', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${widget.invoiceNumber} · ${widget.customerName}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppTextField(
                label: 'Amount',
                hint: widget.maxAmount.toStringAsFixed(2),
                controller: _amountCtrl,
                prefixIcon: Icons.attach_money_rounded,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final d = double.tryParse(v ?? '');
                  if (d == null || d <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Payment date',
                    prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                    suffixIcon: Icon(Icons.expand_more_rounded),
                  ),
                  child: Text(_dateFmt.format(_date),
                      style: theme.textTheme.bodyMedium),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Payment method', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: PaymentMethod.values.map((m) {
                  final selected = m == _method;
                  return ChoiceChip(
                    label: Text(_methodLabel(m)),
                    selected: selected,
                    onSelected: (_) => setState(() => _method = m),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Notes (optional)',
                hint: 'Reference number, memo...',
                controller: _notesCtrl,
                prefixIcon: Icons.notes_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryButton(
                label: 'Record payment',
                icon: Icons.check_rounded,
                isLoading: _loading,
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  String _methodLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.bank:
        return 'Bank';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.other:
        return 'Other';
    }
  }
}

Future<bool?> showRecordPaymentDialog(
  BuildContext context, {
  required String invoiceId,
  required String invoiceNumber,
  required String customerName,
  required double maxAmount,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
    builder: (_) => RecordPaymentDialog(
      invoiceId: invoiceId,
      invoiceNumber: invoiceNumber,
      customerName: customerName,
      maxAmount: maxAmount,
    ),
  );
}
