import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_labels.dart';
import '../../../../core/widgets/app_form_sheet.dart';
import '../../domain/entities/medication.dart';

Future<void> showMedicationSheet({
  required BuildContext context,
  required int selectedWeekday,
  required Future<void> Function(MedicationFormValue value) onSubmit,
  Medication? initialMedication,
  Future<void> Function()? onDelete,
}) {
  return showAppModalSheet<void>(
    context: context,
    heightFactor: 0.94,
    builder: (_) => MedicationSheet(
      selectedWeekday: selectedWeekday,
      initialMedication: initialMedication,
      onSubmit: onSubmit,
      onDelete: onDelete,
    ),
  );
}

class MedicationFormValue {
  const MedicationFormValue({
    required this.name,
    required this.dosage,
    required this.baseTimeInMinutes,
    required this.frequency,
    required this.notificationsEnabled,
    required this.selectedWeekday,
  });

  final String name;
  final String dosage;
  final int baseTimeInMinutes;
  final MedicationFrequency frequency;
  final bool notificationsEnabled;
  final int selectedWeekday;
}

class MedicationSheet extends StatefulWidget {
  const MedicationSheet({
    super.key,
    required this.selectedWeekday,
    required this.onSubmit,
    this.initialMedication,
    this.onDelete,
  });

  final int selectedWeekday;
  final Medication? initialMedication;
  final Future<void> Function(MedicationFormValue value) onSubmit;
  final Future<void> Function()? onDelete;

  @override
  State<MedicationSheet> createState() => _MedicationSheetState();
}

class _MedicationSheetState extends State<MedicationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialMedication?.name ?? '',
  );
  late final _dosageController = TextEditingController(
    text: widget.initialMedication?.dosage ?? '',
  );
  late int _baseTimeInMinutes =
      widget.initialMedication?.timesInMinutes.first ?? -1;
  late MedicationFrequency _frequency =
      widget.initialMedication?.frequency ?? MedicationFrequency.onceDaily;
  late bool _notificationsEnabled =
      widget.initialMedication?.notificationsEnabled ?? true;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialMedication != null;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final initialTime = _baseTimeInMinutes < 0
        ? const TimeOfDay(hour: 8, minute: 0)
        : TimeOfDay(
            hour: _baseTimeInMinutes ~/ 60,
            minute: _baseTimeInMinutes % 60,
          );
    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selected != null) {
      setState(() => _baseTimeInMinutes = selected.hour * 60 + selected.minute);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_baseTimeInMinutes < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите время приема.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(
        MedicationFormValue(
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          baseTimeInMinutes: _baseTimeInMinutes,
          frequency: _frequency,
          notificationsEnabled: _notificationsEnabled,
          selectedWeekday: widget.selectedWeekday,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить препарат.')),
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
      title: 'Удалить препарат?',
      message: 'Препарат будет удален из локального хранилища.',
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
          const SnackBar(content: Text('Не удалось удалить препарат.')),
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
      title: _isEditing ? 'Редактировать препарат' : 'Новый препарат',
      busy: _isSubmitting,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Название препарата',
              hintText: 'напр. Лизиноприл',
              controller: _nameController,
              accentColor: const Color(0xFF18A8CC),
              validator: requiredFieldValidator,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Дозировка',
              hintText: 'напр. 10 мг',
              controller: _dosageController,
              accentColor: const Color(0xFF18A8CC),
              validator: requiredFieldValidator,
            ),
            const SizedBox(height: 20),
            AppPickerField(
              label: 'Время',
              text: _baseTimeInMinutes < 0
                  ? null
                  : formatMinutesAsClock(_baseTimeInMinutes),
              placeholder: '--:--',
              onTap: _isSubmitting ? null : _pickTime,
              accentColor: const Color(0xFF18A8CC),
              suffixIcon: const Icon(
                Icons.access_time_rounded,
                color: Color(0xFF8FA1BC),
              ),
            ),
            const SizedBox(height: 20),
            const AppFieldLabel('Частота приема'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: MedicationFrequency.values
                  .map(
                    (frequency) => AppChoiceChip(
                      label: medicationFrequencyLabel(frequency),
                      selected: frequency == _frequency,
                      onTap: _isSubmitting
                          ? null
                          : () => setState(() => _frequency = frequency),
                      selectedColor: const Color(0xFF18A8CC),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF9EF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF12A64A),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Включить уведомления',
                      style: TextStyle(
                        color: Color(0xFF12203F),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: _notificationsEnabled,
                    onChanged: _isSubmitting
                        ? null
                        : (value) =>
                              setState(() => _notificationsEnabled = value),
                    activeThumbColor: const Color(0xFF1DB954),
                  ),
                ],
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
                      label: 'Обновить препарат',
                      color: const Color(0xFF18A8CC),
                      disabledColor: const Color(0xFF99D8E7),
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
                  label: 'Добавить препарат',
                  color: const Color(0xFF18A8CC),
                  disabledColor: const Color(0xFF99D8E7),
                  onPressed: _submit,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String medicationFrequencyLabel(MedicationFrequency frequency) {
  switch (frequency) {
    case MedicationFrequency.onceDaily:
      return '1 раз в день';
    case MedicationFrequency.twiceDaily:
      return '2 раза в день';
    case MedicationFrequency.threeTimesDaily:
      return '3 раза в день';
    case MedicationFrequency.weekly:
      return '1 раз в неделю';
  }
}

String formatMedicationTime(int totalMinutes) {
  return formatMinutesAsClock(totalMinutes);
}
