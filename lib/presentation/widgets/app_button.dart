import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

enum AppButtonVariant { primary, secondary, outlined, ghost, danger }
enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      AppButtonSize.small => 38.0,
      AppButtonSize.medium => AppSizes.buttonHeight,
      AppButtonSize.large => 58.0,
    };

    final fontSize = switch (size) {
      AppButtonSize.small => 12.0,
      AppButtonSize.medium => 14.0,
      AppButtonSize.large => 16.0,
    };

    final padding = switch (size) {
      AppButtonSize.small => const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      AppButtonSize.medium => const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      AppButtonSize.large => const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    };

    switch (variant) {
      case AppButtonVariant.primary:
        return _buildPrimary(height, fontSize, padding, context);
      case AppButtonVariant.secondary:
        return _buildSecondary(height, fontSize, padding, context);
      case AppButtonVariant.outlined:
        return _buildOutlined(height, fontSize, padding, context);
      case AppButtonVariant.ghost:
        return _buildGhost(height, fontSize, padding, context);
      case AppButtonVariant.danger:
        return _buildDanger(height, fontSize, padding, context);
    }
  }

  Widget _buildChild(double fontSize) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == AppButtonVariant.outlined || variant == AppButtonVariant.ghost
                ? AppColors.primary
                : Colors.white,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600)),
        ],
      );
    }

    return Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600));
  }

  Widget _buildPrimary(double height, double fontSize, EdgeInsets padding, BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
          elevation: 0,
        ),
        child: _buildChild(fontSize),
      ),
    );
  }

  Widget _buildSecondary(double height, double fontSize, EdgeInsets padding, BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
          elevation: 0,
        ),
        child: _buildChild(fontSize),
      ),
    );
  }

  Widget _buildOutlined(double height, double fontSize, EdgeInsets padding, BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        ),
        child: _buildChild(fontSize),
      ),
    );
  }

  Widget _buildGhost(double height, double fontSize, EdgeInsets padding, BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        ),
        child: _buildChild(fontSize),
      ),
    );
  }

  Widget _buildDanger(double height, double fontSize, EdgeInsets padding, BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
          elevation: 0,
        ),
        child: _buildChild(fontSize),
      ),
    );
  }
}

// Gradient button
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = AppSizes.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
