import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/billing/billing_providers.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/business_profile_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  static const _termsUrl = 'https://quoswift.app/terms';
  static const _privacyUrl = 'https://quoswift.app/privacy';

  Future<Offering?>? _offeringFuture;
  Package? _selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _offeringFuture = ref.read(revenueCatServiceProvider).getCurrentOffering();
  }

  Future<void> _markPro() async {
    final repo = ref.read(businessProfileRepositoryProvider);
    try {
      await repo.setSubscriptionTier('pro');
    } catch (_) {
      // Don't block UX — server may already be authoritative via webhook.
    }
  }

  Future<void> _onSubscribe() async {
    final pkg = _selected;
    if (pkg == null || _busy) return;
    setState(() => _busy = true);
    try {
      final ok = await ref.read(revenueCatServiceProvider).purchasePackage(pkg);
      if (!ok) {
        _showSnack('Purchase did not complete.');
        return;
      }
      await _markPro();
      if (!mounted) return;
      _showSnack('Welcome to Pro! 🎉');
      Navigator.of(context).maybePop();
    } on PlatformException catch (e) {
      // RevenueCat throws PlatformException for user-cancel as well.
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code != PurchasesErrorCode.purchaseCancelledError) {
        _showSnack('Purchase failed: ${e.message ?? code.name}');
      }
    } catch (e) {
      _showSnack('Purchase failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onRestore() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ok = await ref.read(revenueCatServiceProvider).restorePurchases();
      if (ok) {
        await _markPro();
        if (!mounted) return;
        _showSnack('Subscription restored.');
        Navigator.of(context).maybePop();
      } else {
        _showSnack('No active subscription found.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = ref.watch(revenueCatServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuoSwift Pro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            _Hero(),
            const SizedBox(height: AppSpacing.xxl),
            _BenefitList(),
            const SizedBox(height: AppSpacing.xxl),
            if (!service.isConfigured)
              _NotConfiguredCard()
            else
              FutureBuilder<Offering?>(
                future: _offeringFuture,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final offering = snap.data;
                  if (offering == null || offering.availablePackages.isEmpty) {
                    return _NoOfferingCard(
                      onRetry: () => setState(() {
                        _offeringFuture = service.getCurrentOffering();
                      }),
                    );
                  }
                  // Auto-select annual if present, else first package.
                  _selected ??= offering.annual ?? offering.availablePackages.first;
                  return Column(
                    children: offering.availablePackages
                        .map((p) => _PackageTile(
                              package: p,
                              selected: identical(_selected, p),
                              onTap: () => setState(() => _selected = p),
                            ))
                        .toList(),
                  );
                },
              ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              onPressed: _busy || _selected == null ? null : _onSubscribe,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.primary,
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Subscribe'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _busy ? null : _onRestore,
              child: const Text('Restore purchases'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Subscription auto-renews. Cancel anytime in your App Store '
              'or Google Play account settings.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _open(_termsUrl),
                  child: const Text('Terms'),
                ),
                const Text('·'),
                TextButton(
                  onPressed: () => _open(_privacyUrl),
                  child: const Text('Privacy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.workspace_premium_rounded,
              size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Go unlimited with Pro',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Send more, brand better, get paid faster.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BenefitList extends StatelessWidget {
  static const _items = <(IconData, String)>[
    (Icons.all_inclusive_rounded, 'Unlimited invoices & quotations'),
    (Icons.water_drop_outlined, 'No watermark on PDFs'),
    (Icons.palette_outlined, 'All premium PDF templates'),
    (Icons.notifications_active_outlined, 'Smart payment reminders'),
    (Icons.support_agent_outlined, 'Priority support'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (icon, label) in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: Text(label, style: theme.textTheme.bodyLarge)),
              ],
            ),
          ),
      ],
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.package,
    required this.selected,
    required this.onTap,
  });

  final Package package;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = package.storeProduct;
    final isAnnual = package.packageType == PackageType.annual;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.lightDivider,
              width: selected ? 2 : 1,
            ),
            color: selected
                ? AppColors.primary.withValues(alpha: 0.06)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? AppColors.primary : Colors.grey,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isAnnual ? 'Yearly' : 'Monthly',
                          style: theme.textTheme.titleMedium,
                        ),
                        if (isAnnual) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'BEST VALUE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.priceString +
                          (isAnnual ? ' / year' : ' / month'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotConfiguredCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning),
      ),
      child: const Text(
        'Billing is not configured for this build. Pass '
        '--dart-define=RC_IOS_KEY=appl_xxx and RC_ANDROID_KEY=goog_xxx '
        'to enable in-app purchases.',
      ),
    );
  }
}

class _NoOfferingCard extends StatelessWidget {
  const _NoOfferingCard({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Couldn't load subscription plans."),
        const SizedBox(height: AppSpacing.sm),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
