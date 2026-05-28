import 'package:flutter/material.dart';

import '../../../../core/ui/app_error_feedback.dart';
import '../../../../core/widgets/app_form_sheet.dart';

Future<void> showCustomMetricSheet({
  required BuildContext context,
  required Future<void> Function(CustomMetricFormValue value) onSubmit,
  CustomMetricFormValue? initialValue,
  Future<void> Function()? onDelete,
}) {
  return showAppModalSheet<void>(
    context: context,
    heightFactor: 0.94,
    builder: (_) => CustomMetricSheet(
      onSubmit: onSubmit,
      initialValue: initialValue,
      onDelete: onDelete,
    ),
  );
}

class CustomMetricFormValue {
  const CustomMetricFormValue({
    required this.name,
    required this.unit,
    required this.targetMin,
    required this.targetMax,
  });

  final String name;
  final String unit;
  final double targetMin;
  final double targetMax;
}

class CustomMetricSheet extends StatefulWidget {
  const CustomMetricSheet({
    super.key,
    required this.onSubmit,
    this.initialValue,
    this.onDelete,
  });

  final Future<void> Function(CustomMetricFormValue value) onSubmit;
  final CustomMetricFormValue? initialValue;
  final Future<void> Function()? onDelete;

  @override
  State<CustomMetricSheet> createState() => _CustomMetricSheetState();
}

class _CustomMetricSheetState extends State<CustomMetricSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialValue?.name ?? '',
  );
  late final _unitController = TextEditingController(
    text: widget.initialValue?.unit ?? '',
  );
  late final _targetMinController = TextEditingController(
    text: widget.initialValue == null
        ? ''
        : _formatDecimal(widget.initialValue!.targetMin),
  );
  late final _targetMaxController = TextEditingController(
    text: widget.initialValue == null
        ? ''
        : _formatDecimal(widget.initialValue!.targetMax),
  );
  bool _isSubmitting = false;
  bool _isDeleting = false;

  bool get _isEditing => widget.initialValue != null;
  bool get _isBusy => _isSubmitting || _isDeleting;

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _targetMinController.dispose();
    _targetMaxController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final minValue = double.parse(
      _targetMinController.text.trim().replaceAll(',', '.'),
    );
    final maxValue = double.parse(
      _targetMaxController.text.trim().replaceAll(',', '.'),
    );

    if (minValue >= maxValue) {
      showAppErrorSnackBar(
        context,
        'Верхняя граница должна быть больше нижней.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(
        CustomMetricFormValue(
          name: _nameController.text.trim(),
          unit: _unitController.text.trim(),
          targetMin: minValue,
          targetMax: maxValue,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        showAppErrorSnackBarForException(
          context,
          error,
          fallbackMessage: _isEditing
              ? 'Не удалось обновить метрику.'
              : 'Не удалось создать метрику.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _delete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null) {
      return;
    }

    final shouldDelete = await showDeleteConfirmationDialog(
      context,
      title: 'Удалить метрику?',
      message:
          'Метрика и все сохраненные значения будут удалены из локального хранилища.',
    );
    if (!shouldDelete) {
      return;
    }

    setState(() => _isDeleting = true);

    try {
      await onDelete();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        showAppErrorSnackBarForException(
          context,
          error,
          fallbackMessage: 'Не удалось удалить метрику.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormSheet(
      title: _isEditing ? 'Редактировать метрику' : 'Своя метрика',
      busy: _isBusy,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Название метрики',
              hintText: 'например, Мочевая кислота',
              controller: _nameController,
              accentColor: const Color(0xFF8B38F6),
              validator: requiredFieldValidator,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Единица измерения',
              hintText: 'например, мг/дл',
              controller: _unitController,
              accentColor: const Color(0xFF8B38F6),
              validator: requiredFieldValidator,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Нижняя граница',
              hintText: 'например, 3.5',
              controller: _targetMinController,
              accentColor: const Color(0xFF8B38F6),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: decimalNumberValidator,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Верхняя граница',
              hintText: 'например, 7.2',
              controller: _targetMaxController,
              accentColor: const Color(0xFF8B38F6),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: decimalNumberValidator,
            ),
            const SizedBox(height: 28),
            if (_isEditing && widget.onDelete != null) ...[
              Row(
                children: [
                  Expanded(
                    child: AppBusyOutlinedButton(
                      busy: _isDeleting,
                      label: 'Удалить',
                      color: const Color(0xFFEF4444),
                      onPressed: _delete,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: AppBusyFilledButton(
                      busy: _isSubmitting,
                      label: 'Обновить метрику',
                      color: const Color(0xFF8B38F6),
                      disabledColor: const Color(0xFFC8A7FA),
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: AppBusyFilledButton(
                  busy: _isSubmitting,
                  label: 'Создать метрику',
                  color: const Color(0xFF8B38F6),
                  disabledColor: const Color(0xFFC8A7FA),
                  onPressed: _submit,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDecimal(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }
}
