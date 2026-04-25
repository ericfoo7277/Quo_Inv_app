import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/responsive_content.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'My Business');
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  String _currency = 'USD';

  static const _currencies = ['USD', 'EUR', 'GBP', 'MYR', 'SGD', 'AUD'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _taxIdCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Saved!')));
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
                      child: Icon(
                        Icons.business_rounded,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {},
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
            ResponsiveContent(
              maxWidth: 640,
              child: Form(
                key: _formKey,
                child: AppCard(
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
                      AppTextField(
                        label: 'Tax / GST ID',
                        hint: 'e.g. US123456789',
                        controller: _taxIdCtrl,
                        prefixIcon: Icons.receipt_outlined,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: 'Website',
                        hint: 'https://yourcompany.com',
                        controller: _websiteCtrl,
                        prefixIcon: Icons.language_rounded,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      DropdownButtonFormField<String>(
                        value: _currency,
                        decoration: const InputDecoration(
                          labelText: 'Default currency',
                          prefixIcon: Icon(Icons.currency_exchange_rounded,
                              size: 20),
                        ),
                        items: _currencies
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _currency = v);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ResponsiveContent(
              maxWidth: 640,
              child: PrimaryButton(
                label: 'Save changes',
                icon: Icons.check_rounded,
                onPressed: _save,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}
