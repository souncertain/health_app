import 'package:flutter/material.dart';

import '../../domain/entities/health_metric_item.dart';
import '../metrics_visuals.dart';

Future<void> showLogMetricValueSheet({
  required BuildContext context,
  required HealthMetricItem metric,
  required Future<void> Function(LogMetricValueFormValue value) onSubmit,
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
        heightFactor: 0.86,
        alignment: Alignment.bottomCenter,
        child: LogMetricValueSheet(metric: metric, onSubmit: onSubmit),
      );
    },
  );
}

class LogMetricValueFormValue {
  const LogMetricValueFormValue({
    required this.value,
    required this.recordedOn,
  });

  final double value;
  final DateTime recordedOn;
}

class LogMetricValueSheet extends StatefulWidget {
  const LogMetricValueSheet({
    super.key,
    required this.metric,
    required this.onSubmit,
  });

  final HealthMetricItem metric;
  final Future<void> Function(LogMetricValueFormValue value) onSubmit;

  @override
  State<LogMetricValueSheet> createState() => _LogMetricValueSheetState();
}

class _LogMetricValueSheetState extends State<LogMetricValueSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late DateTime _selectedDate;
  bool _isSubmitting = false;

  bool get _selectedDateHasExistingValue =>
      widget.metric.recordForDate(_selectedDate) != null;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController();
    _selectedDate = HealthMetricItem.normalizeDate(DateTime.now());
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _selectedDate = HealthMetricItem.normalizeDate(selected);
    });
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
        LogMetricValueFormValue(
          value: double.parse(
            _valueController.text.trim().replaceAll(',', '.'),
          ),
          recordedOn: _selectedDate,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the metric value.')),
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
    final visuals = MetricVisualPalette.fromStyle(widget.metric.visualStyle);

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
                      'Log ${widget.metric.title}',
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
              const SizedBox(height: 4),
              Text(
                'Normal range: '
                '${_formatMetricNumber(widget.metric.targetMin)}-'
                '${_formatMetricNumber(widget.metric.targetMax)} ${widget.metric.unit}',
                style: const TextStyle(
                  color: Color(0xFF8DA2C0),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: visuals.iconBackground,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    visuals.icon,
                    color: visuals.accentColor,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: visuals.accentColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter ${widget.metric.unit}',
                  hintStyle: TextStyle(
                    color: visuals.accentColor.withValues(alpha: 0.45),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF6FCFF),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 24,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: Color(0xFFD7E3F3),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: visuals.accentColor,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: Color(0xFFEF4444),
                      width: 2,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: Color(0xFFEF4444),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Enter a value';
                  }
                  if (double.tryParse(trimmed.replaceAll(',', '.')) == null) {
                    return 'Enter a number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  widget.metric.unit,
                  style: const TextStyle(
                    color: Color(0xFF8DA2C0),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              InkWell(
                onTap: _isSubmitting ? null : _pickDate,
                borderRadius: BorderRadius.circular(22),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
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
                      Icon(
                        Icons.calendar_today_rounded,
                        color: visuals.accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _formatDisplayDate(_selectedDate),
                          style: const TextStyle(
                            color: Color(0xFF12203F),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF8FA1BC),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedDateHasExistingValue) ...[
                const SizedBox(height: 10),
                const Text(
                  'A saved value already exists for this date. Saving will replace it.',
                  style: TextStyle(
                    color: Color(0xFF8DA2C0),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: visuals.accentColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: visuals.accentColor.withValues(
                      alpha: 0.5,
                    ),
                    elevation: 12,
                    shadowColor: visuals.accentColor.withValues(alpha: 0.28),
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
                      : const Text(
                          'Save Value',
                          style: TextStyle(
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
}

String _formatDisplayDate(DateTime date) {
  const monthNames = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${monthNames[date.month]} ${date.day}, ${date.year}';
}

String _formatMetricNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  final singleDecimal = value.toStringAsFixed(1);
  if (double.parse(singleDecimal) == value) {
    return singleDecimal;
  }
  return value.toStringAsFixed(2);
}
