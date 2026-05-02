import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../shared/providers/business_profile_provider.dart';

/// Lets the user customise the default notes / payment instructions block
/// pre-filled into new quotations and invoices.
///
/// Backed by `business_profiles.default_quotation_notes`,
/// `default_invoice_notes`, `payment_instructions`.
class DefaultNotesScreen extends ConsumerStatefulWidget {
  const DefaultNotesScreen({super.key});

  @override
  ConsumerState<DefaultNotesScreen> createState() => _DefaultNotesScreenState();
}

class _DefaultNotesScreenState extends ConsumerState<DefaultNotesScreen> {
  final _invoiceNotesCtrl = TextEditingController();
  final _quotationNotesCtrl = TextEditingController();
  final _paymentInstructionsCtrl = TextEditingController();

  bool _populated = false;
  bool _saving = false;

  @override
  void dispose() {
    _invoiceNotesCtrl.dispose();
    _quotationNotesCtrl.dispose();
    _paymentInstructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final profile = ref.read(businessProfileProvider).value;
      if (profile == null) {
        throw StateError('Business profile not loaded yet.');
      }
      final updated = profile.copyWith(
        defaultInvoiceNotes: _invoiceNotesCtrl.text.trim().isEmpty
            ? null
            : _invoiceNotesCtrl.text.trim(),
        defaultQuotationNotes: _quotationNotesCtrl.text.trim().isEmpty
            ? null
            : _quotationNotesCtrl.text.trim(),
        paymentInstructions: _paymentInstructionsCtrl.text.trim().isEmpty
            ? null
            : _paymentInstructionsCtrl.text.trim(),
      );
      await ref.read(businessProfileRepositoryProvider).save(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default notes saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(businessProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Default Notes')),
      body: AsyncValueView(
        value: profileAsync,
        onRetry: () => ref.invalidate(businessProfileProvider),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Text(
                  'Set up your business profile first to configure default notes.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!_populated) {
            _populated = true;
            _invoiceNotesCtrl.text = profile.defaultInvoiceNotes ?? '';
            _quotationNotesCtrl.text = profile.defaultQuotationNotes ?? '';
            _paymentInstructionsCtrl.text = profile.paymentInstructions ?? '';
          }

          return SafeArea(
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
                          label: 'Payment instructions',
                          hint: 'Bank transfer to Maybank 1234-5678-9012',
                          controller: _paymentInstructionsCtrl,
                          prefixIcon: Icons.payments_outlined,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                ResponsiveContent(
                  maxWidth: 640,
                  child: PrimaryButton(
                    label: _saving ? 'Saving…' : 'Save',
                    icon: Icons.check_rounded,
                    onPressed: _saving ? null : _save,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          );
        },
      ),
    );
  }
}
