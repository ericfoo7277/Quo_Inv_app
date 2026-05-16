import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/premium_screen_header.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../shared/models/invoice.dart';
import '../../../shared/models/reminder_setting.dart';
import '../../../shared/providers/business_profile_provider.dart';
import '../../../shared/providers/customers_provider.dart';
import '../../../shared/providers/invoices_provider.dart';
import '../../../shared/providers/reminder_setting_provider.dart';
import '../../../shared/utils/currency_format.dart';
import '../../documents/services/document_share_service.dart';

String _plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);
    // The user-configured days-before-due window. Falls back to 7 while
    // settings load.
    final remindBeforeDays = ref
            .watch(reminderSettingProvider)
            .maybeWhen(data: (s) => s.remindBeforeDays, orElse: () => 7);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load invoices')),
        data: (invoices) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final overdue = invoices
              .where((i) =>
                _shouldRemind(i) &&
                  i.dueDate.isBefore(today))
              .toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

          final dueSoon = invoices
              .where((i) =>
                _shouldRemind(i) &&
                  !i.dueDate.isBefore(today) &&
                  i.dueDate.isBefore(
                      today.add(Duration(days: remindBeforeDays + 1))))
              .toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

          if (overdue.isEmpty && dueSoon.isEmpty) {
            return const EmptyState(
              title: 'All clear!',
              message: 'No overdue or upcoming invoices. Keep it up.',
              icon: Icons.check_circle_outline_rounded,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              const ResponsiveContent(
                child: PremiumScreenHeader(
                  title: 'Reminders',
                  subtitle: 'Overdue and upcoming invoice alerts.',
                  icon: Icons.notifications_active_rounded,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (overdue.isNotEmpty) ...[
                ResponsiveContent(
                  child: SectionHeader(
                    title: 'Overdue',
                    subtitle: '${_plural(overdue.length, 'invoice')} past due',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...overdue.map((inv) => ResponsiveContent(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _ReminderCard(
                          invoice: inv,
                          today: today,
                          isOverdue: true,
                        ),
                      ),
                    )),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (dueSoon.isNotEmpty) ...[
                ResponsiveContent(
                  child: SectionHeader(
                    title: 'Due soon',
                    subtitle:
                        '${_plural(dueSoon.length, 'invoice')} due within $remindBeforeDays days',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...dueSoon.map((inv) => ResponsiveContent(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _ReminderCard(
                          invoice: inv,
                          today: today,
                          isOverdue: false,
                        ),
                      ),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ReminderCard extends ConsumerWidget {
  const _ReminderCard({
    required this.invoice,
    required this.today,
    required this.isOverdue,
  });

  final Invoice invoice;
  final DateTime today;
  final bool isOverdue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final businessCurrency = ref.watch(businessProfileProvider).value?.currency;
    final currency = AppCurrencyFormat.formatter(
      businessCurrency ?? invoice.currency,
    );
    final diff = invoice.dueDate.difference(today).inDays;
    final daysLabel = isOverdue
        ? '${_plural(diff.abs(), 'day')} overdue'
        : diff == 0
            ? 'Due today'
            : 'Due in ${_plural(diff, 'day')}';
    final color = isOverdue ? AppColors.error : AppColors.warning;

    return AppCard(
      onTap: () => context.pushNamed(
        RouteNames.invoiceDetail,
        pathParameters: {'id': invoice.id},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invoice.invoiceNumber,
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(invoice.customerName,
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        StatusPill(label: daysLabel, color: color),
                        StatusPill(
                          label: invoice.status.label,
                          color: invoice.status.color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                currency.format(invoice.balanceDue),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _copy(context, ref),
                  icon: const Icon(Icons.copy_all_rounded, size: 18),
                  label: const Text('Copy message'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _whatsapp(context, ref),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('WhatsApp'),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => context.pushNamed(
                    RouteNames.invoiceDetail,
                    pathParameters: {'id': invoice.id},
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Open'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _composeMessage(WidgetRef ref) {
    final dateFmt = DateFormat.yMMMd();
    final tpl = ref
        .read(reminderSettingProvider)
        .maybeWhen(
          data: (s) => s.messageTemplate,
          orElse: () => ReminderSetting.defaultMessageTemplate,
        );
    final amount = AppCurrencyFormat.format(
      invoice.balanceDue > 0 ? invoice.balanceDue : invoice.total,
      currency:
          ref.read(businessProfileProvider).value?.currency ?? invoice.currency,
    );
    return tpl
        .replaceAll('{customer}', invoice.customerName)
        .replaceAll('{invoice}', invoice.invoiceNumber)
        .replaceAll('{amount}', amount)
        .replaceAll('{due_date}', dateFmt.format(invoice.dueDate));
  }

  Future<void> _copy(BuildContext context, WidgetRef ref) async {
    await Clipboard.setData(ClipboardData(text: _composeMessage(ref)));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder message copied')),
    );
  }

  Future<void> _whatsapp(BuildContext context, WidgetRef ref) async {
    final customer =
        await ref.read(customerByIdProvider(invoice.customerId).future);
    final phone = customer?.whatsappNumber ?? customer?.phone;
    if (!context.mounted) return;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Customer has no phone or WhatsApp number')),
      );
      return;
    }
    await notifyIfFailed(
      context,
      const DocumentShareService().openWhatsApp(
        phone: phone,
        message: _composeMessage(ref),
      ),
    );
  }
}

bool _shouldRemind(Invoice invoice) {
  return invoice.status == InvoiceStatus.sent ||
      invoice.status == InvoiceStatus.partiallyPaid ||
      invoice.status == InvoiceStatus.overdue;
}
