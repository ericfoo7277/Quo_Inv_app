import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/responsive_content.dart';

class DefaultNotesScreen extends StatefulWidget {
  const DefaultNotesScreen({super.key});

  @override
  State<DefaultNotesScreen> createState() => _DefaultNotesScreenState();
}

class _DefaultNotesScreenState extends State<DefaultNotesScreen> {
  final _invoiceNotesCtrl = TextEditingController();
  final _quotationNotesCtrl = TextEditingController();
  final _paymentTermsCtrl = TextEditingController();

  @override
  void dispose() {
    _invoiceNotesCtrl.dispose();
    _quotationNotesCtrl.dispose();
    _paymentTermsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Default notes saved!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Default Notes')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const ResponsiveContent(
              child: PremiumScreenHeader(
                title: 'Default Notes',
                subtitle: 'Pre-filled text added to new documents.',
                icon: Icons.notes_rounded,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ResponsiveContent(
              maxWidth: 640,
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    AppTextField(
                      label: 'Invoice default notes',
                      hint: 'Thank you for your business...',
                      controller: _invoiceNotesCtrl,
                      prefixIcon: Icons.receipt_long_outlined,
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Quotation default notes',
                      hint: 'This quote is valid for 30 days...',
                      controller: _quotationNotesCtrl,
                      prefixIcon: Icons.description_outlined,
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Payment terms',
                      hint: 'Payment due within 14 days',
                      controller: _paymentTermsCtrl,
                      prefixIcon: Icons.payments_outlined,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ResponsiveContent(
              maxWidth: 640,
              child: PrimaryButton(
                label: 'Save',
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
