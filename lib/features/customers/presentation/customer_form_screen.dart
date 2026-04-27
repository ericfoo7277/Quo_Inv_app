import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../shared/models/customer.dart';
import '../../../shared/providers/customers_provider.dart';
import '../../../shared/providers/repository_providers.dart';

const _uuid = Uuid();

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.customerId});

  final String? customerId;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isArchived = false;
  bool _loading = false;
  bool _populated = false;

  bool get _isEdit => widget.customerId != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _populate(Customer c) {
    if (_populated) return;
    _populated = true;
    _nameCtrl.text = c.name;
    _emailCtrl.text = c.email ?? '';
    _companyCtrl.text = c.companyName ?? '';
    _phoneCtrl.text = c.phone ?? '';
    _whatsappCtrl.text = c.whatsappNumber ?? '';
    _addressCtrl.text = c.billingAddress ?? '';
    _notesCtrl.text = c.notes ?? '';
    _isArchived = c.isArchived;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(customerRepositoryProvider);
      final customer = Customer(
        id: _isEdit ? widget.customerId! : _uuid.v4(),
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        companyName: _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        whatsappNumber: _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
        billingAddress: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        isArchived: _isArchived,
      );
      if (_isEdit) {
        await repo.update(customer);
      } else {
        await repo.create(customer);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit) {
      final async = ref.watch(customerByIdProvider(widget.customerId!));
      async.whenData((c) {
        if (c != null) _populate(c);
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Customer' : 'New Customer')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: ResponsiveContent(
            maxWidth: 640,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        AppTextField(
                          label: 'Name *',
                          hint: 'Jane Smith',
                          controller: _nameCtrl,
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Email',
                          hint: 'jane@example.com',
                          controller: _emailCtrl,
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Company',
                          hint: 'Acme Corp',
                          controller: _companyCtrl,
                          prefixIcon: Icons.business_outlined,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Phone',
                          hint: '+1 555 000 0000',
                          controller: _phoneCtrl,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'WhatsApp number',
                          hint: '+1 555 000 0000',
                          controller: _whatsappCtrl,
                          prefixIcon: Icons.chat_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Billing address',
                          hint: '123 Main St, City, Country',
                          controller: _addressCtrl,
                          prefixIcon: Icons.location_on_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Notes',
                          hint: 'Any notes about this customer...',
                          controller: _notesCtrl,
                          prefixIcon: Icons.notes_rounded,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: SwitchListTile(
                      title: const Text('Archive customer'),
                      subtitle: const Text('Hidden from active customer lists'),
                      value: _isArchived,
                      onChanged: (v) => setState(() => _isArchived = v),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(
                    label: 'Save customer',
                    icon: Icons.check_rounded,
                    isLoading: _loading,
                    onPressed: _loading ? null : _save,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
