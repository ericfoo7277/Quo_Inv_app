import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/section_header.dart';
import '../../../shared/providers/business_profile_provider.dart';

/// Lets the user customise the prefix and next-number counter used for
/// quotations and invoices. Backed by `business_profiles.quotation_prefix`,
/// `quotation_next_number`, `invoice_prefix`, `invoice_next_number`.
class NumberingSettingsScreen extends ConsumerStatefulWidget {
  const NumberingSettingsScreen({super.key});

  @override
  ConsumerState<NumberingSettingsScreen> createState() =>
      _NumberingSettingsScreenState();
}

class _NumberingSettingsScreenState
    extends ConsumerState<NumberingSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invPrefixCtrl = TextEditingController();
  final _invNextCtrl = TextEditingController();
  final _quoPrefixCtrl = TextEditingController();
  final _quoNextCtrl = TextEditingController();

  bool _populated = false;
  bool _saving = false;

  @override
  void dispose() {
    _invPrefixCtrl.dispose();
    _invNextCtrl.dispose();
    _quoPrefixCtrl.dispose();
    _quoNextCtrl.dispose();
    super.dispose();
  }

  String _formatPreview(String prefix, String nextRaw) {
    final n = int.tryParse(nextRaw.trim()) ?? 1;
    return '$prefix${n.toString().padLeft(4, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final profile = ref.read(businessProfileProvider).value;
      if (profile == null) {
        throw StateError('Business profile not loaded yet.');
      }
      final updated = profile.copyWith(
        invoicePrefix: _invPrefixCtrl.text.trim(),
        invoiceNextNumber: int.tryParse(_invNextCtrl.text.trim()) ?? 1,
        quotationPrefix: _quoPrefixCtrl.text.trim(),
        quotationNextNumber: int.tryParse(_quoNextCtrl.text.trim()) ?? 1,
      );
      await ref.read(businessProfileRepositoryProvider).save(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Numbering settings saved')),
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
    final theme = Theme.of(context);
    final profileAsync = ref.watch(businessProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Numbering')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load profile: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Text(
                  'Set up your business profile first to configure document numbering.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!_populated) {
            _populated = true;
            _invPrefixCtrl.text = profile.invoicePrefix;
            _invNextCtrl.text = profile.invoiceNextNumber.toString();
            _quoPrefixCtrl.text = profile.quotationPrefix;
            _quoNextCtrl.text = profile.quotationNextNumber.toString();
          }

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                const ResponsiveContent(
                  child: PremiumScreenHeader(
                    title: 'Numbering',
                    subtitle: 'Set prefixes and sequences for your documents.',
                    icon: Icons.tag_rounded,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                ResponsiveContent(
                  maxWidth: 640,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SectionHeader(title: 'Invoices'),
                              const SizedBox(height: AppSpacing.lg),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Prefix',
                                      hint: 'INV-',
                                      controller: _invPrefixCtrl,
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Required'
                                              : null,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Next number',
                                      hint: '1',
                                      controller: _invNextCtrl,
                                      keyboardType: TextInputType.number,
                                      validator: (v) {
                                        final n = int.tryParse(
                                            (v ?? '').trim());
                                        if (n == null || n < 1) {
                                          return 'Must be a positive number';
                                        }
                                        return null;
                                      },
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SectionHeader(title: 'Quotations'),
                              const SizedBox(height: AppSpacing.lg),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Prefix',
                                      hint: 'Q-',
                                      controller: _quoPrefixCtrl,
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Required'
                                              : null,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Next number',
                                      hint: '1',
                                      controller: _quoNextCtrl,
                                      keyboardType: TextInputType.number,
                                      validator: (v) {
                                        final n = int.tryParse(
                                            (v ?? '').trim());
                                        if (n == null || n < 1) {
                                          return 'Must be a positive number';
                                        }
                                        return null;
                                      },
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader(
                                title: 'Preview',
                                subtitle: 'How your next document numbers will look',
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Row(
                                children: [
                                  const Icon(Icons.receipt_long_outlined,
                                      size: 18),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text('Invoice: ',
                                      style: theme.textTheme.bodySmall),
                                  Text(
                                    _formatPreview(_invPrefixCtrl.text,
                                        _invNextCtrl.text),
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  const Icon(Icons.description_outlined,
                                      size: 18),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text('Quotation: ',
                                      style: theme.textTheme.bodySmall),
                                  Text(
                                    _formatPreview(_quoPrefixCtrl.text,
                                        _quoNextCtrl.text),
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ],
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
                    label: 'Save',
                    icon: Icons.check_rounded,
                    isLoading: _saving,
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
