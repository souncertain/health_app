import 'package:flutter/material.dart';

Future<T?> showAppModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double? heightFactor,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: false,
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) {
      final child = builder(context);
      final content = heightFactor == null
          ? child
          : FractionallySizedBox(
              heightFactor: heightFactor,
              alignment: Alignment.bottomCenter,
              child: child,
            );

      return AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: content,
      );
    },
  );
}

class AppFormSheet extends StatelessWidget {
  const AppFormSheet({
    super.key,
    required this.title,
    required this.busy,
    required this.child,
    this.subtitle,
    this.bodySpacing = 28,
    this.bottomPaddingExtra = 24,
  });

  final String title;
  final bool busy;
  final Widget child;
  final Widget? subtitle;
  final double bodySpacing;
  final double bottomPaddingExtra;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom + bottomPaddingExtra;

    return SafeArea(
      top: false,
      bottom: false,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF12203F),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5FB),
                  ),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF7184A2),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              subtitle!,
            ],
            SizedBox(height: bodySpacing),
            child,
          ],
        ),
      ),
    );
  }
}

class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF61738F),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.accentColor,
    this.validator,
    this.keyboardType,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.onTap,
    this.textAlign = TextAlign.start,
    this.suffixIcon,
    this.style,
    this.hintStyle,
    this.contentPadding,
    this.borderRadius = 22,
    this.scrollPadding = const EdgeInsets.fromLTRB(20, 20, 20, 180),
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final Color accentColor;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final VoidCallback? onTap;
  final TextAlign textAlign;
  final Widget? suffixIcon;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final EdgeInsetsGeometry? contentPadding;
  final double borderRadius;
  final EdgeInsets scrollPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          AppFieldLabel(label),
          const SizedBox(height: 12),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          readOnly: readOnly,
          obscureText: obscureText,
          onTap: onTap,
          textAlign: textAlign,
          scrollPadding: scrollPadding,
          style:
              style ??
              const TextStyle(
                color: Color(0xFF12203F),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle:
                hintStyle ??
                const TextStyle(
                  color: Color(0xFF8FA1BC),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
            filled: true,
            fillColor: const Color(0xFFF6FCFF),
            contentPadding:
                contentPadding ??
                const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            suffixIcon: suffixIcon,
            enabledBorder: _border(const Color(0xFFD7E3F3), borderRadius),
            focusedBorder: _border(accentColor, borderRadius),
            errorBorder: _border(const Color(0xFFEF4444), borderRadius),
            focusedErrorBorder: _border(
              const Color(0xFFEF4444),
              borderRadius,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class AppPickerField extends StatelessWidget {
  const AppPickerField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.onTap,
    this.text,
    this.accentColor = const Color(0xFF12203F),
    this.suffixIcon,
  });

  final String label;
  final String placeholder;
  final String? text;
  final VoidCallback? onTap;
  final Color accentColor;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFieldLabel(label),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF6FCFF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 20,
              ),
              suffixIcon:
                  suffixIcon ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF8FA1BC),
                  ),
              enabledBorder: _border(const Color(0xFFD7E3F3), 22),
              focusedBorder: _border(accentColor, 22),
            ),
            child: Text(
              text ?? placeholder,
              style: TextStyle(
                color: text == null
                    ? const Color(0xFF8FA1BC)
                    : const Color(0xFF12203F),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AppBusyFilledButton extends StatelessWidget {
  const AppBusyFilledButton({
    super.key,
    required this.busy,
    required this.label,
    required this.color,
    required this.onPressed,
    this.disabledColor,
  });

  final bool busy;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final Color? disabledColor;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: disabledColor ?? color.withValues(alpha: 0.5),
        elevation: 10,
        shadowColor: color.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
    );
  }
}

class AppBusyOutlinedButton extends StatelessWidget {
  const AppBusyOutlinedButton({
    super.key,
    required this.busy,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final bool busy;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.28), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
      child: busy
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
    );
  }
}

class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.selectedColor,
    this.unselectedColor = const Color(0xFFF1F5FB),
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = const Color(0xFF61738F),
    this.fontSize = 14,
    this.iconSize = 20,
    this.iconSpacing = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final double fontSize;
  final double iconSize;
  final double iconSpacing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? selectedTextColor : unselectedTextColor;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: padding,
        decoration: BoxDecoration(
          color: selected
              ? (selectedColor ?? Theme.of(context).colorScheme.primary)
              : unselectedColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize, color: foreground),
              SizedBox(width: iconSpacing),
            ],
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showDeleteConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF12203F),
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF61738F),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Отмена',
            style: TextStyle(
              color: Color(0xFF7184A2),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'Удалить',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  return result == true;
}

String? requiredFieldValidator(String? value, {String message = 'Обязательное поле'}) {
  return (value?.trim() ?? '').isEmpty ? message : null;
}

String? positiveIntegerValidator(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Обязательное поле';
  }

  final parsed = int.tryParse(trimmed);
  if (parsed == null) {
    return 'Введите число';
  }
  if (parsed <= 0) {
    return 'Значение должно быть больше нуля';
  }
  return null;
}

String? decimalNumberValidator(String? value, {String message = 'Обязательное поле'}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return message;
  }
  return double.tryParse(trimmed.replaceAll(',', '.')) == null
      ? 'Введите число'
      : null;
}

OutlineInputBorder _border(Color color, double radius) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: BorderSide(color: color, width: 2),
  );
}
