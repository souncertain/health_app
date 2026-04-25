import 'package:flutter/material.dart';

import '../../domain/entities/blood_pressure_reading.dart';

Future<void> showBloodPressureReadingSheet({
  required BuildContext context,
  required Future<void> Function(BloodPressureReadingFormValue value) onSubmit,
  BloodPressureReading? initialReading,
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
      return BloodPressureReadingSheet(
        initialReading: initialReading,
        onSubmit: onSubmit,
        onDelete: onDelete,
      );
    },
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
  late final TextEditingController _systolicController;
  late final TextEditingController _diastolicController;
  late final TextEditingController _pulseController;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialReading != null;

  @override
  void initState() {
    super.initState();
    _systolicController = TextEditingController(
      text: widget.initialReading?.systolic.toString() ?? '',
    );
    _diastolicController = TextEditingController(
      text: widget.initialReading?.diastolic.toString() ?? '',
    );
    _pulseController = TextEditingController(
      text: widget.initialReading?.pulse.toString() ?? '',
    );
  }

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

    setState(() {
      _isSubmitting = true;
    });

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
          const SnackBar(content: Text('Could not save the reading.')),
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
          title: const Text('Delete reading?'),
          content: const Text(
            'This measurement will be removed from local storage.',
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
          const SnackBar(content: Text('Could not delete the reading.')),
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
        mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom + 16;

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
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
                        _isEditing ? 'Edit Measurement' : 'Add Measurement',
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
                _ReadingField(
                  label: 'Systolic (mmHg)',
                  hintText: 'e.g. 120',
                  controller: _systolicController,
                ),
                const SizedBox(height: 20),
                _ReadingField(
                  label: 'Diastolic (mmHg)',
                  hintText: 'e.g. 80',
                  controller: _diastolicController,
                ),
                const SizedBox(height: 20),
                _ReadingField(
                  label: 'Pulse (bpm)',
                  hintText: 'e.g. 72',
                  controller: _pulseController,
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
                        child: _SaveReadingButton(
                          busy: _isSubmitting,
                          label: 'Update Reading',
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
                ] else
                  _SaveReadingButton(
                    busy: _isSubmitting,
                    label: 'Save Reading',
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

class _ReadingField extends StatelessWidget {
  const _ReadingField({
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
          keyboardType: TextInputType.number,
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
              borderSide: const BorderSide(color: Color(0xFF1DB954), width: 2),
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

            final parsed = int.tryParse(trimmed);
            if (parsed == null) {
              return 'Enter a number';
            }
            if (parsed <= 0) {
              return 'Must be greater than zero';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _SaveReadingButton extends StatelessWidget {
  const _SaveReadingButton({
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
          backgroundColor: const Color(0xFF1DB954),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF98D7AE),
          elevation: 10,
          shadowColor: const Color(0xFF1DB954).withValues(alpha: 0.25),
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
