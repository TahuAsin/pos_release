import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? maxLength;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText ? _obscureText : false,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      inputFormatters: widget.inputFormatters,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 20,
                  color: AppColors.textSecondaryLight,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : widget.suffixIcon,
        counterText: '',
      ),
    );
  }
}

// Search field
class AppSearchField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final VoidCallback? onClear;

  const AppSearchField({
    super.key,
    this.hint = 'Cari...',
    this.controller,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          suffixIcon: controller?.text.isNotEmpty == true
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    controller?.clear();
                    onClear?.call();
                    onChanged?.call('');
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
