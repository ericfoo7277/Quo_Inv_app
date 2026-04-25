import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/section_header.dart';

class NumberingSettingsScreen extends StatefulWidget {
  const NumberingSettingsScreen({super.key});

  @override
  State<NumberingSettingsScreen> createState() =>
      _NumberingSettingsScreenState();
}

class _NumberingSettingsScreenState extends State<NumberingSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invPrefixCtrl = TextEditingController(text: 'INV');
  final _invNextCtrl = TextEditingController(text: '001');
  final _quoPrefixCtrl = TextEditingController(text: 'QUO');
  final _quoNextCtrl = TextEditingController(text: '001');

  @override
  void dispose() {
    _invPrefixCtrl.dispose();
    _invNextCtrl.dispose();
    _quoPrefixCtrl.dispose();
    _quoNextCtrl.dispose();
    super.dispose();
  }

  String get _invPreview =>
      '${_invPrefixCtrl.text}-${DateTime.now().year}-${_invNextCtrl.text}';
  String get _quoPreview =>
      '${_quoPrefixCtrl.text}-${DateTime.now().year}-${_quoNextCtrl.text}';

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Numbering settings saved!')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Numbering')),
      body: SafeArea(
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
                                  hint: 'INV',
                                  controller: _invPrefixCtrl,
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: AppTextField(
                                  label: 'Next number',
                                  hint: '001',
                                  controller: _invNextCtrl,
                                  keyboardType: TextInputType.number,
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
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
                                  hint: 'QUO',
                                  controller: _quoPrefixCtrl,
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: AppTextField(
                                  label: 'Next number',
                                  hint: '001',
                                  controller: _quoNextCtrl,
                                  keyboardType: TextInputType.number,
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
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
                            subtitle: 'How your document numbers will look',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              const Icon(Icons.receipt_long_outlined, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Text('Invoice: ',
                                  style: theme.textTheme.bodySmall),
                              Text(_invPreview,
                                  style: theme.textTheme.titleSmall),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              const Icon(Icons.description_outlined, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Text('Quotation: ',
                                  style: theme.textTheme.bodySmall),
                              Text(_quoPreview,
                                  style: theme.textTheme.titleSmall),
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
