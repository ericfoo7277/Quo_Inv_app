import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_spacing.dart';
import 'app_card.dart';
import 'responsive_content.dart';

/// Shimmer-animated skeleton list used while a list (invoices, quotations,
/// customers, etc.) is loading from Supabase.
///
/// Renders [itemCount] placeholder rows that mimic the height of a
/// `DocumentCard` / `CustomerCard` so the layout doesn't jump on first paint.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.itemCount = 6, this.itemHeight = 92});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    final highlight = theme.colorScheme.surface;

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: itemCount,
      itemBuilder: (_, __) => ResponsiveContent(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Shimmer.fromColors(
            baseColor: base,
            highlightColor: highlight,
            period: const Duration(milliseconds: 1400),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 160,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 110,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 14,
                    width: 64,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
