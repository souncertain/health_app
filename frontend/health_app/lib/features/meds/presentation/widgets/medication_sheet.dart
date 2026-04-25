import 'package:flutter/material.dart';

import '../../domain/entities/medication.dart';

Future<void> showMedicationSheet({
  required BuildContext context,
  required int selectedWeekday,
  required Future<void> Function(MedicationFormValue value) onSubmit,
  Medication? initialMedication,
  Future<void> Function()? onDelete,
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
        child: MedicationSheet(
          selectedWeekday: selectedWeekday,
          initialMedication: initialMedication,
          onSubmit: onSubmit,
          onDelete: onDelete,
        ),
      );
    },
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
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late int _baseTimeInMinutes;
  late MedicationFrequency _frequency;
  late bool _notificationsEnabled;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialMedication != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialMedication?.name ?? '',
    );
    _dosageController = TextEditingController(
      text: widget.initialMedication?.dosage ?? '',
    );
    _baseTimeInMinutes = widget.initialMedication?.timesInMinutes.first ?? -1;
    _frequency =
        widget.initialMedication?.frequency ?? MedicationFrequency.onceDaily;
    _notificationsEnabled =
        widget.initialMedication?.notificationsEnabled ?? true;
  }

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

    if (selected == null) {
      return;
    }

    setState(() {
      _baseTimeInMinutes = (selected.hour * 60) + selected.minute;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_baseTimeInMinutes < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a time.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

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
          const SnackBar(content: Text('Could not save the medication.')),
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

  Future<void> _delete() async {
    if (widget.onDelete == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete medication?'),
          content: const Text(
            'This medication will be removed from local storage.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onDelete!.call();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete the medication.')),
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

    return RepaintBoundary(
      child: SafeArea(
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
                        _isEditing ? 'Edit Medication' : 'New Medication',
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
                _MedicationField(
                  label: 'Medication Name',
                  hintText: 'e.g. Lisinopril',
                  controller: _nameController,
                ),
                const SizedBox(height: 20),
                _MedicationField(
                  label: 'Dosage',
                  hintText: 'e.g. 10mg',
                  controller: _dosageController,
                ),
                const SizedBox(height: 20),
                Text(
                  'Time',
                  style: const TextStyle(
                    color: Color(0xFF61738F),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _isSubmitting ? null : _pickTime,
                  borderRadius: BorderRadius.circular(22),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FCFF),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFD7E3F3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _baseTimeInMinutes < 0
                                ? '--:--'
                                : formatMedicationTime(_baseTimeInMinutes),
                            style: TextStyle(
                              color: _baseTimeInMinutes < 0
                                  ? const Color(0xFF8FA1BC)
                                  : const Color(0xFF12203F),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.access_time_rounded,
                          color: Color(0xFF8FA1BC),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Frequency',
                  style: const TextStyle(
                    color: Color(0xFF61738F),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: MedicationFrequency.values.map((frequency) {
                    final selected = frequency == _frequency;
                    return GestureDetector(
                      onTap: _isSubmitting
                          ? null
                          : () {
                              setState(() {
                                _frequency = frequency;
                              });
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF18A8CC)
                              : const Color(0xFFF1F5FB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          medicationFrequencyLabel(frequency),
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF61738F),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
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
                          'Enable Notifications',
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
                            : (value) {
                                setState(() {
                                  _notificationsEnabled = value;
                                });
                              },
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
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : _delete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFFFD4D4)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _MedicationSubmitButton(
                          busy: _isSubmitting,
                          label: 'Update Medication',
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
                ] else
                  _MedicationSubmitButton(
                    busy: _isSubmitting,
                    label: 'Add Medication',
                    onPressed: _submit,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicationField extends StatelessWidget {
  const _MedicationField({
    required this.label,
    required this.hintText,
    required this.controller,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;

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
              borderSide: const BorderSide(color: Color(0xFF18A8CC), width: 2),
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
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              return 'Required';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _MedicationSubmitButton extends StatelessWidget {
  const _MedicationSubmitButton({
    required this.busy,
    required this.label,
    required this.onPressed,
  });

  final bool busy;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF18A8CC),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF99D8E7),
          elevation: 10,
          shadowColor: const Color(0xFF18A8CC).withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
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
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

String medicationFrequencyLabel(MedicationFrequency frequency) {
  switch (frequency) {
    case MedicationFrequency.onceDaily:
      return 'Once daily';
    case MedicationFrequency.twiceDaily:
      return 'Twice daily';
    case MedicationFrequency.threeTimesDaily:
      return '3x daily';
    case MedicationFrequency.weekly:
      return 'Weekly';
  }
}

String formatMedicationTime(int totalMinutes) {
  final hour = totalMinutes ~/ 60;
  final minute = totalMinutes % 60;
  final displayHour = hour == 0
      ? 12
      : hour > 12
      ? hour - 12
      : hour;
  final suffix = hour >= 12 ? 'PM' : 'AM';
  return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
}
