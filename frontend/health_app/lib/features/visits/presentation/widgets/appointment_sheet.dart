import 'package:flutter/material.dart';

import '../../../../core/ui/app_error_feedback.dart';
import '../../../../core/utils/date_time_labels.dart';
import '../../../../core/widgets/app_form_sheet.dart';
import '../../domain/entities/medical_visit.dart';

Future<void> showAppointmentSheet({
  required BuildContext context,
  required Future<void> Function(AppointmentFormValue value) onSubmit,
  MedicalVisit? initialVisit,
}) {
  return showAppModalSheet<void>(
    context: context,
    heightFactor: 0.94,
    builder: (_) =>
        AppointmentSheet(initialVisit: initialVisit, onSubmit: onSubmit),
  );
}

class AppointmentFormValue {
  const AppointmentFormValue({
    required this.doctorName,
    required this.specialty,
    required this.appointmentDate,
    required this.timeInMinutes,
    required this.location,
    required this.visitType,
  });

  final String doctorName;
  final String specialty;
  final DateTime appointmentDate;
  final int timeInMinutes;
  final String location;
  final MedicalVisitType visitType;
}

class AppointmentSheet extends StatefulWidget {
  const AppointmentSheet({
    super.key,
    required this.onSubmit,
    this.initialVisit,
  });

  final Future<void> Function(AppointmentFormValue value) onSubmit;
  final MedicalVisit? initialVisit;

  @override
  State<AppointmentSheet> createState() => _AppointmentSheetState();
}

class _AppointmentSheetState extends State<AppointmentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _doctorController = TextEditingController(
    text: widget.initialVisit?.doctorName ?? '',
  );
  late final _specialtyController = TextEditingController(
    text: widget.initialVisit?.specialty ?? '',
  );
  late final _locationController = TextEditingController(
    text: widget.initialVisit?.location ?? '',
  );
  late DateTime _selectedDate = MedicalVisit.normalizeDate(
    widget.initialVisit?.appointmentDate ?? DateTime.now(),
  );
  int? _selectedTimeInMinutes;
  late MedicalVisitType _visitType;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialVisit != null;

  @override
  void initState() {
    super.initState();
    _selectedTimeInMinutes = widget.initialVisit?.timeInMinutes;
    _visitType = widget.initialVisit?.visitType ?? MedicalVisitType.oneTime;
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _specialtyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (selected != null) {
      setState(() => _selectedDate = MedicalVisit.normalizeDate(selected));
    }
  }

  Future<void> _pickTime() async {
    final initialTime = TimeOfDay(
      hour: (_selectedTimeInMinutes ?? 9 * 60) ~/ 60,
      minute: (_selectedTimeInMinutes ?? 9 * 60) % 60,
    );
    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selected != null) {
      setState(
        () => _selectedTimeInMinutes = selected.hour * 60 + selected.minute,
      );
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_selectedTimeInMinutes == null) {
      showAppErrorSnackBar(context, 'Выберите время приёма.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(
        AppointmentFormValue(
          doctorName: _doctorController.text.trim(),
          specialty: _specialtyController.text.trim(),
          appointmentDate: _selectedDate,
          timeInMinutes: _selectedTimeInMinutes!,
          location: _locationController.text.trim(),
          visitType: _visitType,
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
              ? 'Не удалось обновить запись.'
              : 'Не удалось создать запись.',
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
      title: _isEditing ? 'Редактировать запись' : 'Новая запись',
      busy: _isSubmitting,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Имя врача',
              hintText: 'напр. д-р Иван Петров',
              controller: _doctorController,
              accentColor: const Color(0xFFEF9200),
              validator: requiredFieldValidator,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Специализация',
              hintText: 'напр. Кардиолог',
              controller: _specialtyController,
              accentColor: const Color(0xFFEF9200),
              validator: requiredFieldValidator,
            ),
            const SizedBox(height: 20),
            AppPickerField(
              label: 'Дата',
              text: formatDotDate(_selectedDate),
              placeholder: 'dd.MM.yyyy',
              onTap: _isSubmitting ? null : _pickDate,
              accentColor: const Color(0xFFEF9200),
              suffixIcon: const Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFFD7E3F3),
              ),
            ),
            const SizedBox(height: 20),
            AppPickerField(
              label: 'Время',
              text: _selectedTimeInMinutes == null
                  ? null
                  : formatMinutesAsClock(_selectedTimeInMinutes!),
              placeholder: '--:--',
              onTap: _isSubmitting ? null : _pickTime,
              accentColor: const Color(0xFFEF9200),
              suffixIcon: const Icon(
                Icons.schedule_rounded,
                color: Color(0xFFD7E3F3),
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Место',
              hintText: 'Клиника / медицинский центр',
              controller: _locationController,
              accentColor: const Color(0xFFEF9200),
              validator: requiredFieldValidator,
            ),
            const SizedBox(height: 24),
            const AppFieldLabel('Тип визита'),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 360;

                Widget buildVisitTypeChip({
                  required String label,
                  required IconData icon,
                  required bool selected,
                  required VoidCallback onTap,
                }) {
                  return Expanded(
                    child: AppChoiceChip(
                      label: label,
                      icon: icon,
                      selected: selected,
                      onTap: onTap,
                      selectedColor: const Color(0xFFEB8600),
                      unselectedTextColor: const Color(0xFF7C8FAE),
                      fontSize: isCompact ? 14.5 : 16,
                      iconSize: isCompact ? 18 : 20,
                      iconSpacing: isCompact ? 8 : 10,
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 12 : 18,
                        vertical: 16,
                      ),
                    ),
                  );
                }

                return Row(
                  children: [
                    buildVisitTypeChip(
                      label: 'Разовый',
                      icon: Icons.calendar_today_rounded,
                      selected: _visitType == MedicalVisitType.oneTime,
                      onTap: () =>
                          setState(() => _visitType = MedicalVisitType.oneTime),
                    ),
                    SizedBox(width: isCompact ? 10 : 12),
                    buildVisitTypeChip(
                      label: 'Регулярный',
                      icon: Icons.sync_rounded,
                      selected: _visitType == MedicalVisitType.recurring,
                      onTap: () => setState(
                        () => _visitType = MedicalVisitType.recurring,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: AppBusyFilledButton(
                busy: _isSubmitting,
                label: _isEditing ? 'Обновить запись' : 'Записаться',
                color: const Color(0xFFEF9200),
                disabledColor: const Color(0xFFF5C16D),
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
