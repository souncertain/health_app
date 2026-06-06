import 'package:flutter/material.dart';

import '../../../../core/ui/app_error_feedback.dart';
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
    required this.recordedAt,
  });

  final int systolic;
  final int diastolic;
  final int pulse;
  final DateTime recordedAt;
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
  late DateTime _recordedAt =
      widget.initialReading?.recordedAt.toLocal() ?? DateTime.now();
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
          recordedAt: _recordedAt,
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
          fallbackMessage: 'Не удалось сохранить измерение.',
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
      message:
          'Это измерение будет удалено из локального хранилища и очереди синхронизации.',
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
    } catch (error) {
      if (mounted) {
        showAppErrorSnackBarForException(
          context,
          error,
          fallbackMessage: 'Не удалось удалить измерение.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickRecordedAtDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Дата измерения',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _recordedAt = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        _recordedAt.hour,
        _recordedAt.minute,
      );
    });
  }

  String _formatRecordedAt(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
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
              hintText: 'например, 120',
              controller: _systolicController,
              accentColor: const Color(0xFF1DB954),
              keyboardType: TextInputType.number,
              validator: positiveIntegerValidator,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Нижнее (мм рт. ст.)',
              hintText: 'например, 80',
              controller: _diastolicController,
              accentColor: const Color(0xFF1DB954),
              keyboardType: TextInputType.number,
              validator: positiveIntegerValidator,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Пульс (уд/мин)',
              hintText: 'например, 72',
              controller: _pulseController,
              accentColor: const Color(0xFF1DB954),
              keyboardType: TextInputType.number,
              validator: positiveIntegerValidator,
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _isSubmitting ? null : _pickRecordedAtDate,
              borderRadius: BorderRadius.circular(22),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFD8E7DC)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF1DB954),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Дата измерения',
                            style: TextStyle(
                              color: Color(0xFF5B6F85),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatRecordedAt(_recordedAt),
                            style: const TextStyle(
                              color: Color(0xFF0C1C46),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.expand_more_rounded,
                      color: Color(0xFF8AA0B4),
                    ),
                  ],
                ),
              ),
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
