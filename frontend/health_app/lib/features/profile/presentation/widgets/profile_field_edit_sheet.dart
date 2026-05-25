import 'package:flutter/material.dart';

import '../../../../core/widgets/app_form_sheet.dart';

Future<void> showProfileFieldEditSheet({
  required BuildContext context,
  required String title,
  required String label,
  required String hintText,
  required String initialValue,
  required Future<void> Function(String value) onSubmit,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
}) {
  return showAppModalSheet<void>(
    context: context,
    heightFactor: 0.58,
    builder: (_) => _SingleFieldSheet(
      title: title,
      label: label,
      hintText: hintText,
      initialValue: initialValue,
      keyboardType: keyboardType,
      validator: validator,
      onSubmit: onSubmit,
    ),
  );
}

Future<void> showEmergencyContactEditSheet({
  required BuildContext context,
  required String initialName,
  required String initialDetails,
  required Future<void> Function(String name, String details) onSubmit,
}) {
  return showAppModalSheet<void>(
    context: context,
    heightFactor: 0.72,
    builder: (_) => _EmergencyContactSheet(
      initialName: initialName,
      initialDetails: initialDetails,
      onSubmit: onSubmit,
    ),
  );
}

class _SingleFieldSheet extends StatefulWidget {
  const _SingleFieldSheet({
    required this.title,
    required this.label,
    required this.hintText,
    required this.initialValue,
    required this.onSubmit,
    required this.keyboardType,
    this.validator,
  });

  final String title;
  final String label;
  final String hintText;
  final String initialValue;
  final Future<void> Function(String value) onSubmit;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  @override
  State<_SingleFieldSheet> createState() => _SingleFieldSheetState();
}

class _SingleFieldSheetState extends State<_SingleFieldSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initialValue);
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_controller.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: widget.title,
      busy: _isSubmitting,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              label: widget.label,
              hintText: widget.hintText,
              controller: _controller,
              accentColor: const Color(0xFF18B552),
              keyboardType: widget.keyboardType,
              validator: widget.validator,
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: AppBusyFilledButton(
                busy: _isSubmitting,
                label: 'Сохранить',
                color: const Color(0xFF18B552),
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyContactSheet extends StatefulWidget {
  const _EmergencyContactSheet({
    required this.initialName,
    required this.initialDetails,
    required this.onSubmit,
  });

  final String initialName;
  final String initialDetails;
  final Future<void> Function(String name, String details) onSubmit;

  @override
  State<_EmergencyContactSheet> createState() => _EmergencyContactSheetState();
}

class _EmergencyContactSheetState extends State<_EmergencyContactSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initialName);
  late final _detailsController = TextEditingController(
    text: widget.initialDetails,
  );
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        _nameController.text.trim(),
        _detailsController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: 'Экстренный контакт',
      busy: _isSubmitting,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              label: 'Имя контакта',
              hintText: 'например, Мария Петрова',
              controller: _nameController,
              accentColor: const Color(0xFF18B552),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Контакт',
              hintText: 'Телефон, Telegram или другой способ связи',
              controller: _detailsController,
              accentColor: const Color(0xFF18B552),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: AppBusyFilledButton(
                busy: _isSubmitting,
                label: 'Сохранить',
                color: const Color(0xFF18B552),
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
