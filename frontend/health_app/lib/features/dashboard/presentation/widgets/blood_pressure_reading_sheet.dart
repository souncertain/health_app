import 'package:flutter/material.dart';

import '../../../../core/widgets/app_form_sheet.dart';
import '../../domain/entities/blood_pressure_reading.dart';

Future<void> showBloodPressureReadingSheet({
  required BuildContext context,
  required Future<void> Function(BloodPressureReadingFormValue value) onSubmit,
  BloodPressureReading? initialReading,
  Future<void> Function()? onDelete,
}) {
  return showAppModalSheet<void>(
    context: context,
    builder: (_) => BloodPressureReadingSheet(
      initialReading: initialReading,
      onSubmit: onSubmit,
      onDelete: onDelete,
    ),
  );
}

class BloodPressureReadingFormValue {
  const BloodPressureReadingFormValue({
    required this.systolic,
    required this.diastolic,
    required this.pulse,
  });

  final int systolic;
  final int diastolic;
  final int pulse;
}

class BloodPressureReadingSheet extends StatefulWidget {
  const BloodPressureReadingSheet({
    super.key,
    required this.onSubmit,
    this.initialReading,
    this.onDelete,
  });

  final BloodPressureReading? initialReading;
  final Future<void> Function(BloodPressureReadingFormValue value) onSubmit;
  final Future<void> Function()? onDelete;

  @override
  State<BloodPressureReadingSheet> createState() =>
      _BloodPressureReadingSheetState();
}

class _BloodPressureReadingSheetState extends State<BloodPressureReadingSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _systolicController = TextEditingController(
    text: widget.initialReading?.systolic.toString() ?? '',
  );
  late final _diastolicController = TextEditingController(
    text: widget.initialReading?.diastolic.toString() ?? '',
  );
  late final _pulseController = TextEditingController(
    text: widget.initialReading?.pulse.toString() ?? '',
  );
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialReading != null;

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(
        BloodPressureReadingFormValue(
          systolic: int.parse(_systolicController.text),
          diastolic: int.parse(_diastolicController.text),
          pulse: int.parse(_pulseController.text),
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить измерение.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _delete() async {
    if (widget.onDelete == null) {
      return;
    }

    final confirmed = await showDeleteConfirmationDialog(
      context,
      title: 'Удалить запись?',
      message: 'Это измерение будет удалено из локального хранилища.',
    );
    if (!confirmed) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onDelete!.call();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось удалить измерение.')),
        );
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
      title: _isEditing ? 'Редактировать измерение' : 'Добавить измерение',
      busy: _isSubmitting,
      bottomPaddingExtra: 16,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Верхнее (мм рт. ст.)',
              hintText: 'напр. 120',
              controller: _systolicController,
              accentColor: const Color(0xFF1DB954),
              keyboardType: TextInputType.number,
              validator: positiveIntegerValidator,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Нижнее (мм рт. ст.)',
              hintText: 'напр. 80',
              controller: _diastolicController,
              accentColor: const Color(0xFF1DB954),
              keyboardType: TextInputType.number,
              validator: positiveIntegerValidator,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Пульс (уд/мин)',
              hintText: 'напр. 72',
              controller: _pulseController,
              accentColor: const Color(0xFF1DB954),
              keyboardType: TextInputType.number,
              validator: positiveIntegerValidator,
            ),
            const SizedBox(height: 28),
            if (_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: AppBusyOutlinedButton(
                      busy: _isSubmitting,
                      label: 'Удалить',
                      color: const Color(0xFFEF4444),
                      onPressed: _delete,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppBusyFilledButton(
                      busy: _isSubmitting,
                      label: 'Обновить запись',
                      color: const Color(0xFF1DB954),
                      disabledColor: const Color(0xFF98D7AE),
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
                  label: 'Сохранить запись',
                  color: const Color(0xFF1DB954),
                  disabledColor: const Color(0xFF98D7AE),
                  onPressed: _submit,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
