import 'package:flutter/material.dart';

import '../../domain/entities/medical_visit.dart';

Future<void> showAppointmentSheet({
  required BuildContext context,
  required Future<void> Function(AppointmentFormValue value) onSubmit,
  MedicalVisit? initialVisit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.94,
        alignment: Alignment.bottomCenter,
        child: AppointmentSheet(initialVisit: initialVisit, onSubmit: onSubmit),
      );
    },
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
  late final TextEditingController _doctorController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _locationController;
  late DateTime _selectedDate;
  int? _selectedTimeInMinutes;
  late MedicalVisitType _visitType;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialVisit != null;

  @override
  void initState() {
    super.initState();
    _doctorController = TextEditingController(
      text: widget.initialVisit?.doctorName ?? '',
    );
    _specialtyController = TextEditingController(
      text: widget.initialVisit?.specialty ?? '',
    );
    _locationController = TextEditingController(
      text: widget.initialVisit?.location ?? '',
    );
    _selectedDate = MedicalVisit.normalizeDate(
      widget.initialVisit?.appointmentDate ?? DateTime.now(),
    );
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

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedDate = MedicalVisit.normalizeDate(selected);
    });
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

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedTimeInMinutes = selected.hour * 60 + selected.minute;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_selectedTimeInMinutes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a time for the appointment.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Could not update the appointment.'
                  : 'Could not create the appointment.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding =
        mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom + 24;

    return SafeArea(
      top: false,
      bottom: false,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Appointment' : 'New Appointment',
                      style: const TextStyle(
                        color: Color(0xFF12203F),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
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
              const SizedBox(height: 28),
              _AppointmentField(
                label: "Doctor's Name",
                hintText: 'Dr. John Smith',
                controller: _doctorController,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 20),
              _AppointmentField(
                label: 'Specialty',
                hintText: 'e.g. Cardiologist',
                controller: _specialtyController,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),
              _PickerField(
                label: 'Date',
                text: _formatDateField(_selectedDate),
                placeholder: 'dd.MM.yyyy',
                onTap: _pickDate,
              ),
              const SizedBox(height: 20),
              _PickerField(
                label: 'Time',
                text: _selectedTimeInMinutes == null
                    ? null
                    : _formatTime(_selectedTimeInMinutes!),
                placeholder: '--:--',
                onTap: _pickTime,
              ),
              const SizedBox(height: 20),
              _AppointmentField(
                label: 'Location',
                hintText: 'Hospital / Clinic name',
                controller: _locationController,
                keyboardType: TextInputType.streetAddress,
              ),
              const SizedBox(height: 24),
              const Text(
                'Visit Type',
                style: TextStyle(
                  color: Color(0xFF61738F),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _VisitTypeOption(
                      label: 'One-Time',
                      icon: Icons.calendar_today_rounded,
                      selected: _visitType == MedicalVisitType.oneTime,
                      onTap: () {
                        setState(() {
                          _visitType = MedicalVisitType.oneTime;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _VisitTypeOption(
                      label: 'Recurring',
                      icon: Icons.sync_rounded,
                      selected: _visitType == MedicalVisitType.recurring,
                      onTap: () {
                        setState(() {
                          _visitType = MedicalVisitType.recurring;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEF9200),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFF5C16D),
                    elevation: 10,
                    shadowColor: const Color(
                      0xFFEF9200,
                    ).withValues(alpha: 0.28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _isEditing
                              ? 'Update Appointment'
                              : 'Book Appointment',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateField(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
  }

  String _formatTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final isPm = hour >= 12;
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute ${isPm ? 'PM' : 'AM'}';
  }
}

class _AppointmentField extends StatelessWidget {
  const _AppointmentField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.keyboardType,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF61738F),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: Color(0xFF12203F),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF8FA1BC),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: const Color(0xFFF6FCFF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 20,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: Color(0xFFD7E3F3), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: Color(0xFFEF9200), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
          ),
          validator: (value) {
            if ((value?.trim() ?? '').isEmpty) {
              return 'Required';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.placeholder,
    required this.onTap,
    this.text,
  });

  final String label;
  final String placeholder;
  final String? text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF61738F),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
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
              suffixIcon: const Icon(
                Icons.schedule_rounded,
                color: Color(0xFFD7E3F3),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(
                  color: Color(0xFFD7E3F3),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(
                  color: Color(0xFFEF9200),
                  width: 2,
                ),
              ),
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

class _VisitTypeOption extends StatelessWidget {
  const _VisitTypeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEB8600) : const Color(0xFFF1F5FB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.white : const Color(0xFF7C8FAE),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF61738F),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
