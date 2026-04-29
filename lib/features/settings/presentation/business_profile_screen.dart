import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../shared/models/business_profile.dart';
import '../../../shared/providers/business_profile_provider.dart';

const _uuid = Uuid();

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState
    extends ConsumerState<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _paymentInstructionsCtrl = TextEditingController();
  final _defaultQuotationNotesCtrl = TextEditingController();
  final _defaultInvoiceNotesCtrl = TextEditingController();
  final _quoPrefixCtrl = TextEditingController(text: 'Q-');
  final _invPrefixCtrl = TextEditingController(text: 'INV-');
  final _quoNextCtrl = TextEditingController(text: '1');
  final _invNextCtrl = TextEditingController(text: '1');
  final _timezoneCtrl = TextEditingController(text: 'Asia/Kuala_Lumpur');
  String _currency = 'MYR';
  String? _profileId;
  String? _logoUrl;
  bool _loading = false;
  bool _populated = false;

  static const _currencies = ['USD', 'EUR', 'GBP', 'MYR', 'SGD', 'AUD'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile =
        await ref.read(businessProfileRepositoryProvider).fetch();
    if (profile != null && mounted && !_populated) {
      _populated = true;
      _profileId = profile.id;
      _logoUrl = profile.logoUrl;
      _nameCtrl.text = profile.businessName;
      _emailCtrl.text = profile.email ?? '';
      _phoneCtrl.text = profile.phone ?? '';
      _addressCtrl.text = profile.address ?? '';
      _paymentInstructionsCtrl.text = profile.paymentInstructions ?? '';
      _defaultQuotationNotesCtrl.text = profile.defaultQuotationNotes ?? '';
      _defaultInvoiceNotesCtrl.text = profile.defaultInvoiceNotes ?? '';
      _quoPrefixCtrl.text = profile.quotationPrefix;
      _invPrefixCtrl.text = profile.invoicePrefix;
      _quoNextCtrl.text = profile.quotationNextNumber.toString();
      _invNextCtrl.text = profile.invoiceNextNumber.toString();
      _timezoneCtrl.text = profile.timezone;
      setState(() => _currency = profile.currency);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _paymentInstructionsCtrl.dispose();
    _defaultQuotationNotesCtrl.dispose();
    _defaultInvoiceNotesCtrl.dispose();
    _quoPrefixCtrl.dispose();
    _invPrefixCtrl.dispose();
    _quoNextCtrl.dispose();
    _invNextCtrl.dispose();
    _timezoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _loading = true);
    try {
      final bytes = await picked.readAsBytes();
      final url =
          await ref.read(businessProfileRepositoryProvider).uploadLogo(bytes);
      if (mounted) {
        if (url.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Logo upload requires Supabase. Running in mock mode.'),
            ),
          );
        } else {
          setState(() => _logoUrl = url);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logo uploaded.')),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logo upload failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final profile = BusinessProfile(
        id: _profileId ?? _uuid.v4(),
        businessName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        address:
            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        currency: _currency,
        logoUrl: _logoUrl,
        paymentInstructions: _paymentInstructionsCtrl.text.trim().isEmpty
            ? null
            : _paymentInstructionsCtrl.text.trim(),
        defaultQuotationNotes:
            _defaultQuotationNotesCtrl.text.trim().isEmpty
                ? null
                : _defaultQuotationNotesCtrl.text.trim(),
        defaultInvoiceNotes: _defaultInvoiceNotesCtrl.text.trim().isEmpty
            ? null
            : _defaultInvoiceNotesCtrl.text.trim(),
        quotationPrefix: _quoPrefixCtrl.text.trim().isEmpty
            ? 'Q-'
            : _quoPrefixCtrl.text.trim(),
        invoicePrefix: _invPrefixCtrl.text.trim().isEmpty
            ? 'INV-'
            : _invPrefixCtrl.text.trim(),
        quotationNextNumber: int.tryParse(_quoNextCtrl.text) ?? 1,
        invoiceNextNumber: int.tryParse(_invNextCtrl.text) ?? 1,
        timezone: _timezoneCtrl.text.trim().isEmpty
            ? 'Asia/Kuala_Lumpur'
            : _timezoneCtrl.text.trim(),
      );
      await ref.read(businessProfileRepositoryProvider).save(profile);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved!')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Business Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const ResponsiveContent(
              child: PremiumScreenHeader(
                title: 'Business Profile',
                subtitle: 'Appears on your invoices and quotations.',
                icon: Icons.business_rounded,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ResponsiveContent(
              maxWidth: 640,
              child: Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.10),
                      backgroundImage: _logoUrl != null
                          ? CachedNetworkImageProvider(_logoUrl!)
                          : null,
                      child: _logoUrl == null
                          ? Icon(
                              Icons.business_rounded,
                              size: 40,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _loading ? null : _pickAndUploadLogo,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primary,
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            // — Contact details —
            ResponsiveContent(
              maxWidth: 640,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          AppTextField(
                            label: 'Business name *',
                            hint: 'Acme Corp',
                            controller: _nameCtrl,
                            prefixIcon: Icons.business_outlined,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            label: 'Email',
                            hint: 'billing@yourcompany.com',
                            controller: _emailCtrl,
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
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
                            label: 'Address',
                            hint: '123 Main St, City, Country',
                            controller: _addressCtrl,
                            prefixIcon: Icons.location_on_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          DropdownButtonFormField<String>(
                            value: _currency,
                            decoration: const InputDecoration(
                              labelText: 'Default currency',
                              prefixIcon: Icon(
                                  Icons.currency_exchange_rounded,
                                  size: 20),
                            ),
                            items: _currencies
                                .map((c) => DropdownMenuItem(
                                    value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _currency = v);
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            label: 'Timezone',
                            hint: 'e.g. Asia/Kuala_Lumpur',
                            controller: _timezoneCtrl,
                            prefixIcon: Icons.schedule_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // — Document numbering —
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Document numbering',
                              style: theme.textTheme.titleSmall),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Quotation prefix',
                                  hint: 'QUO',
                                  controller: _quoPrefixCtrl,
                                  prefixIcon: Icons.description_outlined,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: AppTextField(
                                  label: 'Next #',
                                  hint: '1',
                                  controller: _quoNextCtrl,
                                  prefixIcon: Icons.numbers_rounded,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Invoice prefix',
                                  hint: 'INV',
                                  controller: _invPrefixCtrl,
                                  prefixIcon: Icons.receipt_long_outlined,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: AppTextField(
                                  label: 'Next #',
                                  hint: '1',
                                  controller: _invNextCtrl,
                                  prefixIcon: Icons.numbers_rounded,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // — Default text blocks —
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        children: [
                          AppTextField(
                            label: 'Default payment instructions',
                            hint:
                                'Bank transfer to account: XYZ...',
                            controller: _paymentInstructionsCtrl,
                            prefixIcon: Icons.account_balance_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            label: 'Default quotation notes',
                            hint: 'This quotation is valid for 30 days...',
                            controller: _defaultQuotationNotesCtrl,
                            prefixIcon: Icons.notes_rounded,
                            maxLines: 3,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            label: 'Default invoice notes',
                            hint: 'Thank you for your business...',
                            controller: _defaultInvoiceNotesCtrl,
                            prefixIcon: Icons.notes_rounded,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ResponsiveContent(
              maxWidth: 640,
              child: PrimaryButton(
                label: 'Save changes',
                icon: Icons.check_rounded,
                isLoading: _loading,
                onPressed: _loading ? null : _save,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}
