import 'package:flutter/material.dart';

Future<void> showCustomMetricSheet({
  required BuildContext context,
  required Future<void> Function(CustomMetricFormValue value) onSubmit,
  CustomMetricFormValue? initialValue,
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
        child: CustomMetricSheet(
          onSubmit: onSubmit,
          initialValue: initialValue,
          onDelete: onDelete,
        ),
      );
    },
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
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _targetMinController;
  late final TextEditingController _targetMaxController;
  bool _isSubmitting = false;
  bool _isDeleting = false;

  bool get _isEditing => widget.initialValue != null;
  bool get _isBusy => _isSubmitting || _isDeleting;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialValue?.name ?? '',
    );
    _unitController = TextEditingController(
      text: widget.initialValue?.unit ?? '',
    );
    _targetMinController = TextEditingController(
      text: widget.initialValue == null
          ? ''
          : _formatDecimal(widget.initialValue!.targetMin),
    );
    _targetMaxController = TextEditingController(
      text: widget.initialValue == null
          ? ''
          : _formatDecimal(widget.initialValue!.targetMax),
    );
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Target max must be greater than target min.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

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
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Could not update the metric.'
                  : 'Could not create the metric.',
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

  Future<void> _delete() async {
    final onDelete = widget.onDelete;
    if (onDelete == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Delete metric?',
            style: TextStyle(
              color: Color(0xFF12203F),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'This will remove the metric and all of its saved values from local storage.',
            style: TextStyle(
              color: Color(0xFF61738F),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF7184A2),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await onDelete();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete the metric.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
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
                      _isEditing ? 'Edit Metric' : 'Custom Metric',
                      style: const TextStyle(
                        color: Color(0xFF12203F),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isBusy
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
              _MetricField(
                label: 'Metric Name',
                hintText: 'e.g. Uric Acid',
                controller: _nameController,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 20),
              _MetricField(
                label: 'Unit',
                hintText: 'e.g. mg/dL',
                controller: _unitController,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 20),
              _MetricField(
                label: 'Target Min',
                hintText: 'e.g. 3.5',
                controller: _targetMinController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _decimalValidator,
              ),
              const SizedBox(height: 20),
              _MetricField(
                label: 'Target Max',
                hintText: 'e.g. 7.2',
                controller: _targetMaxController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _decimalValidator,
              ),
              const SizedBox(height: 28),
              if (_isEditing && widget.onDelete != null)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isBusy ? null : _delete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: BorderSide(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.28),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                        child: _isDeleting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFEF4444),
                                  ),
                                ),
                              )
                            : const Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(flex: 2, child: _buildSubmitButton()),
                  ],
                )
              else
                SizedBox(width: double.infinity, child: _buildSubmitButton()),
            ],
          ),
        ),
      ),
    );
  }

  String? _decimalValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Required';
    }

    final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
    if (parsed == null) {
      return 'Enter a number';
    }

    return null;
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: _isBusy ? null : _submit,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF8B38F6),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFC8A7FA),
        elevation: 10,
        shadowColor: const Color(0xFF8B38F6).withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
      child: _isSubmitting
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              _isEditing ? 'Update Metric' : 'Create Metric',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
    );
  }

  String _formatDecimal(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }
}

class _MetricField extends StatelessWidget {
  const _MetricField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.keyboardType,
    this.validator,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String? value)? validator;

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
              borderSide: const BorderSide(color: Color(0xFF8B38F6), width: 2),
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
          validator:
              validator ??
              (value) {
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
