import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/section_header.dart';
import '../../../shared/models/invoice.dart';
import '../../../shared/providers/customers_provider.dart';
import '../../../shared/providers/invoices_provider.dart';
import '../../../shared/providers/repository_providers.dart';

const _uuid = Uuid();

class _LineItem {
  _LineItem({
    this.itemName = '',
    this.qty = '1',
    this.unitPrice = '0',
  });
  String itemName;
  String qty;
  String unitPrice;

  double get total =>
      (double.tryParse(qty) ?? 0) * (double.tryParse(unitPrice) ?? 0);
}

class InvoiceFormScreen extends ConsumerStatefulWidget {
  const InvoiceFormScreen({super.key, this.invoiceId});

  final String? invoiceId;

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCustomerId;
  String? _selectedCustomerName;
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  InvoiceStatus _status = InvoiceStatus.draft;
  final _taxRateCtrl = TextEditingController(text: '0');
  final _discountCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  final _paymentInstructionsCtrl = TextEditingController();
  final List<_LineItem> _items = [_LineItem()];
  String? _originalNumber;
  bool _loading = false;
  bool _populated = false;

  final _dateFmt = DateFormat.yMMMd();

  bool get _isEdit => widget.invoiceId != null;

  @override
  void dispose() {
    _taxRateCtrl.dispose();
    _discountCtrl.dispose();
    _notesCtrl.dispose();
    _paymentInstructionsCtrl.dispose();
    super.dispose();
  }

  void _populate(Invoice inv) {
    if (_populated) return;
    _populated = true;
    _originalNumber = inv.invoiceNumber;
    _selectedCustomerId = inv.customerId;
    _selectedCustomerName = inv.customerName;
    _issueDate = inv.issueDate;
    _dueDate = inv.dueDate;
    _status = inv.status;
    _taxRateCtrl.text = (inv.taxRate * 100).toStringAsFixed(2);
    _discountCtrl.text = inv.discountAmount.toStringAsFixed(2);
    _notesCtrl.text = inv.notes ?? '';
    _paymentInstructionsCtrl.text = inv.paymentInstructions ?? '';
    _items
      ..clear()
      ..addAll(inv.items.map((i) => _LineItem(
            itemName: i.itemName,
            qty: i.quantity.toString(),
            unitPrice: i.unitPrice.toString(),
          )));
  }

  Future<void> _pickDate(bool isIssue) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isIssue ? _issueDate : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
    );
    if (picked != null) {
      setState(() {
        if (isIssue) {
          _issueDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  double get _subtotal => _items.fold(0.0, (s, i) => s + i.total);
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0;
  double get _taxAmount =>
      (_subtotal - _discount) *
      ((double.tryParse(_taxRateCtrl.text) ?? 0) / 100);
  double get _total => _subtotal - _discount + _taxAmount;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a customer')));
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(invoiceRepositoryProvider);
      final taxRate = (double.tryParse(_taxRateCtrl.text) ?? 0) / 100;
      final items = _items
          .where((i) => i.itemName.trim().isNotEmpty)
          .map((i) => InvoiceLineItem(
                itemName: i.itemName.trim(),
                quantity: double.tryParse(i.qty) ?? 1,
                unitPrice: double.tryParse(i.unitPrice) ?? 0,
              ))
          .toList();
      final invoice = Invoice(
        id: _isEdit ? widget.invoiceId! : _uuid.v4(),
        invoiceNumber: _isEdit
            ? (_originalNumber ?? widget.invoiceId!)
            : 'INV-${DateTime.now().millisecondsSinceEpoch}',
        customerId: _selectedCustomerId!,
        customerName: _selectedCustomerName ?? '',
        issueDate: _issueDate,
        dueDate: _dueDate,
        items: items,
        status: _isEdit ? _status : InvoiceStatus.draft,
        taxRate: taxRate,
        discountAmount: _discount,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        paymentInstructions: _paymentInstructionsCtrl.text.trim().isEmpty
            ? null
            : _paymentInstructionsCtrl.text.trim(),
      );
      if (_isEdit) {
        await repo.update(invoice);
      } else {
        await repo.create(invoice);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit) {
      ref.watch(invoiceByIdProvider(widget.invoiceId!)).whenData((inv) {
        if (inv != null) _populate(inv);
      });
    }

    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Invoice' : 'New Invoice')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              // Customer picker
              ResponsiveContent(
                maxWidth: 640,
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: customersAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Failed to load customers'),
                    data: (customers) => DropdownButtonFormField<String>(
                      initialValue: _selectedCustomerId,
                      decoration: const InputDecoration(
                        labelText: 'Customer',
                        prefixIcon:
                            Icon(Icons.person_outline_rounded, size: 20),
                      ),
                      items: customers
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        final c = customers.firstWhere((c) => c.id == v);
                        setState(() {
                          _selectedCustomerId = v;
                          _selectedCustomerName = c.name;
                        });
                      },
                      validator: (v) =>
                          v == null ? 'Please select a customer' : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Dates
              ResponsiveContent(
                maxWidth: 640,
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      _DatePickerRow(
                        label: 'Issue date',
                        date: _issueDate,
                        formatter: _dateFmt,
                        onTap: () => _pickDate(true),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _DatePickerRow(
                        label: 'Due date',
                        date: _dueDate,
                        formatter: _dateFmt,
                        onTap: () => _pickDate(false),
                      ),
                      if (_isEdit) ...[
                        const SizedBox(height: AppSpacing.lg),
                        DropdownButtonFormField<InvoiceStatus>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            prefixIcon: Icon(Icons.flag_outlined, size: 20),
                          ),
                          items: InvoiceStatus.values
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.label),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _status = v);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Line items
              ResponsiveContent(
                maxWidth: 640,
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeader(
                        title: 'Line items',
                        action: TextButton.icon(
                          onPressed: () =>
                              setState(() => _items.add(_LineItem())),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add item'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ..._items.asMap().entries.map((e) => _LineItemRow(
                            key: ValueKey(e.key),
                            item: e.value,
                            index: e.key,
                            canRemove: _items.length > 1,
                            onRemove: () =>
                                setState(() => _items.removeAt(e.key)),
                            onChanged: () => setState(() {}),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Tax, discount & notes
              ResponsiveContent(
                maxWidth: 640,
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Discount amount',
                        hint: '0.00',
                        controller: _discountCtrl,
                        prefixIcon: Icons.discount_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: 'Tax rate (%)',
                        hint: '0',
                        controller: _taxRateCtrl,
                        prefixIcon: Icons.percent_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: 'Notes',
                        hint: 'Thank you for your business...',
                        controller: _notesCtrl,
                        prefixIcon: Icons.notes_rounded,
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: 'Payment instructions',
                        hint: 'Bank transfer to account...',
                        controller: _paymentInstructionsCtrl,
                        prefixIcon: Icons.account_balance_outlined,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Totals
              ResponsiveContent(
                maxWidth: 640,
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      _TotalRow(label: 'Subtotal', amount: _subtotal),
                      if (_discount > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _TotalRow(label: 'Discount', amount: -_discount),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      _TotalRow(
                        label:
                            'Tax (${(double.tryParse(_taxRateCtrl.text) ?? 0).toStringAsFixed(1)}%)',
                        amount: _taxAmount,
                      ),
                      const Divider(height: AppSpacing.xxl),
                      _TotalRow(label: 'Total', amount: _total, isTotal: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ResponsiveContent(
                maxWidth: 640,
                child: PrimaryButton(
                  label: 'Save invoice',
                  icon: Icons.check_rounded,
                  isLoading: _loading,
                  onPressed: _loading ? null : _save,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.label,
    required this.date,
    required this.formatter,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final DateFormat formatter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
          suffixIcon: const Icon(Icons.expand_more_rounded),
        ),
        child: Text(formatter.format(date), style: theme.textTheme.bodyMedium),
      ),
    );
  }
}

class _LineItemRow extends StatefulWidget {
  const _LineItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  final _LineItem item;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  State<_LineItemRow> createState() => _LineItemRowState();
}

class _LineItemRowState extends State<_LineItemRow> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.item.itemName);
    _qtyCtrl = TextEditingController(text: widget.item.qty);
    _priceCtrl = TextEditingController(text: widget.item.unitPrice);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: AppTextField(
              hint: 'Item name',
              controller: _descCtrl,
              onChanged: (v) {
                widget.item.itemName = v;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppTextField(
              hint: 'Qty',
              controller: _qtyCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) {
                widget.item.qty = v;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: AppTextField(
              hint: 'Price',
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) {
                widget.item.unitPrice = v;
                widget.onChanged();
              },
            ),
          ),
          if (widget.canRemove)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: widget.onRemove,
            ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  final String label;
  final double amount;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style =
        isTotal ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          NumberFormat.simpleCurrency().format(amount),
          style: style?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
