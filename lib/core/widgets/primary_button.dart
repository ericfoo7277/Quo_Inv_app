import 'package:flutter/material.dart';

import '../constants/app_radius.dart';
import '../constants/app_shadows.dart';
import '../theme/app_colors.dart';

/// Premium gradient primary action button.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final child = Container(
      decoration: BoxDecoration(
        gradient: disabled ? null : AppColors.primaryGradient,
        color: disabled
            ? Theme.of(context).disabledColor.withValues(alpha: 0.2)
            : null,
        borderRadius: AppRadius.button,
        boxShadow: disabled ? null : AppShadows.glow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          else ...[
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.button,
      child: InkWell(
        borderRadius: AppRadius.button,
        onTap: disabled ? null : onPressed,
        child: child,
      ),
    );
  }
}
