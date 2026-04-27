import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_names.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/responsive_content.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  String _currency = 'MYR';
  bool _loading = false;

  static const _currencies = ['USD', 'EUR', 'GBP', 'MYR', 'SGD', 'AUD'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _taxIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _loading = false);
    context.goNamed(RouteNames.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Setup')),
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
                  const PremiumScreenHeader(
                    title: 'Set up your business',
                    subtitle: 'This information appears on your invoices and quotes.',
                    icon: Icons.business_rounded,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        AppTextField(
                          label: 'Business name *',
                          hint: 'Acme Corp',
                          controller: _nameCtrl,
                          prefixIcon: Icons.business_outlined,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Business name is required' : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Business email',
                          hint: 'billing@yourcompany.com',
                          controller: _emailCtrl,
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Phone',
                          hint: '60123456789',
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
                        DropdownButtonFormField<String>(
                          value: _currency,
                          decoration: const InputDecoration(
                            labelText: 'Default currency',
                            prefixIcon: Icon(Icons.currency_exchange_rounded, size: 20),
                          ),
                          items: _currencies
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _currency = v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(
                    label: 'Complete setup',
                    icon: Icons.check_rounded,
                    isLoading: _loading,
                    onPressed: _loading ? null : _submit,
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
