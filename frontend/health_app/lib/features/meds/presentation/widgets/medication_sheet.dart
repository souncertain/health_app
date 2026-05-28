import 'package:flutter/material.dart';

import '../../../../core/ui/app_error_feedback.dart';
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
    required this.timesInMinutes,
    required this.frequency,
    required this.notificationsEnabled,
    required this.selectedWeekday,
  });

  final String name;
  final String dosage;
  final List<int> timesInMinutes;
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
  late MedicationFrequency _frequency;
  late bool _notificationsEnabled;
  late List<int> _timesInMinutes;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialMedication != null;

  @override
  void initState() {
    super.initState();
    _frequency =
        widget.initialMedication?.frequency ?? MedicationFrequency.onceDaily;
    _notificationsEnabled = widget.initialMedication?.notificationsEnabled ?? true;
    _timesInMinutes = _buildInitialTimes();
    _syncTimeSlots();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  int get _requiredTimeSlots {
    switch (_frequency) {
      case MedicationFrequency.onceDaily:
      case MedicationFrequency.dayAfterDay:
      case MedicationFrequency.weekly:
        return 1;
      case MedicationFrequency.twiceDaily:
        return 2;
      case MedicationFrequency.threeTimesDaily:
        return 3;
    }
  }

  List<int> _buildInitialTimes() {
    final initialTimes = List<int>.from(
      widget.initialMedication?.timesInMinutes ?? const [],
    )..sort();
    if (initialTimes.isNotEmpty) {
      return initialTimes;
    }
    return _defaultTimesForFrequency(_frequency);
  }

  List<int> _defaultTimesForFrequency(MedicationFrequency frequency) {
    switch (frequency) {
      case MedicationFrequency.onceDaily:
      case MedicationFrequency.dayAfterDay:
      case MedicationFrequency.weekly:
        return const [8 * 60];
      case MedicationFrequency.twiceDaily:
        return const [8 * 60, 20 * 60];
      case MedicationFrequency.threeTimesDaily:
        return const [8 * 60, 14 * 60, 20 * 60];
    }
  }

  void _syncTimeSlots() {
    final normalized = List<int>.from(_timesInMinutes)..sort();
    while (normalized.length < _requiredTimeSlots) {
      normalized.add(_suggestTimeForSlot(normalized, normalized.length));
    }
    if (normalized.length > _requiredTimeSlots) {
      normalized.removeRange(_requiredTimeSlots, normalized.length);
    }
    normalized.sort();
    _timesInMinutes = normalized;
  }

  int _suggestTimeForSlot(List<int> current, int slotIndex) {
    if (current.isNotEmpty) {
      final baseTime = current.first;
      if (_frequency == MedicationFrequency.twiceDaily && slotIndex == 1) {
        return _normalizeMinutes(baseTime + (12 * 60));
      }
      if (_frequency == MedicationFrequency.threeTimesDaily) {
        if (slotIndex == 1) {
          return _normalizeMinutes(baseTime + (6 * 60));
        }
        if (slotIndex == 2) {
          return _normalizeMinutes(baseTime + (12 * 60));
        }
      }
    }

    final defaults = _defaultTimesForFrequency(_frequency);
    final safeIndex = slotIndex.clamp(0, defaults.length - 1);
    return defaults[safeIndex];
  }

  int _normalizeMinutes(int minutes) {
    const minutesPerDay = 24 * 60;
    final normalized = minutes % minutesPerDay;
    return normalized < 0 ? normalized + minutesPerDay : normalized;
  }

  Future<void> _pickTime(int index) async {
    final initialValue = _timesInMinutes[index];
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialValue ~/ 60,
        minute: initialValue % 60,
      ),
    );

    if (selected != null) {
      final updated = List<int>.from(_timesInMinutes);
      updated[index] = selected.hour * 60 + selected.minute;
      updated.sort();
      setState(() => _timesInMinutes = updated);
    }
  }

  void _selectFrequency(MedicationFrequency frequency) {
    setState(() {
      _frequency = frequency;
      _syncTimeSlots();
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final timesInMinutes = List<int>.from(_timesInMinutes)..sort();
    if (timesInMinutes.toSet().length != timesInMinutes.length) {
      showAppErrorSnackBar(context, 'Время приема не должно повторяться.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(
        MedicationFormValue(
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          timesInMinutes: timesInMinutes,
          frequency: _frequency,
          notificationsEnabled: _notificationsEnabled,
          selectedWeekday: widget.selectedWeekday,
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
          fallbackMessage: 'Не удалось сохранить препарат.',
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
    } catch (error) {
      if (mounted) {
        showAppErrorSnackBarForException(
          context,
          error,
          fallbackMessage: 'Не удалось удалить препарат.',
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
                          : () => _selectFrequency(frequency),
                      selectedColor: const Color(0xFF18A8CC),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            Column(
              children: List<Widget>.generate(_timesInMinutes.length, (index) {
                final label = _timesInMinutes.length == 1
                    ? 'Время приема'
                    : 'Время приема ${index + 1}';
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == _timesInMinutes.length - 1 ? 0 : 16,
                  ),
                  child: AppPickerField(
                    label: label,
                    text: formatMinutesAsClock(_timesInMinutes[index]),
                    placeholder: '--:--',
                    onTap: _isSubmitting ? null : () => _pickTime(index),
                    accentColor: const Color(0xFF18A8CC),
                    suffixIcon: const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF8FA1BC),
                    ),
                  ),
                );
              }),
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
    case MedicationFrequency.dayAfterDay:
      return 'Через день';
    case MedicationFrequency.weekly:
      return '1 раз в неделю';
  }
}

String formatMedicationTime(int totalMinutes) {
  return formatMinutesAsClock(totalMinutes);
}
