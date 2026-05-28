import 'package:flutter/material.dart';

import '../../../../core/ui/app_error_feedback.dart';
import '../../../../core/utils/date_time_labels.dart';
import '../../../../core/widgets/app_form_sheet.dart';
import '../../domain/entities/health_metric_item.dart';
import '../metrics_visuals.dart';

Future<void> showLogMetricValueSheet({
  required BuildContext context,
  required HealthMetricItem metric,
  required Future<void> Function(LogMetricValueFormValue value) onSubmit,
}) {
  return showAppModalSheet<void>(
    context: context,
    heightFactor: 0.86,
    builder: (_) => LogMetricValueSheet(metric: metric, onSubmit: onSubmit),
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
  late final _valueController = TextEditingController();
  late DateTime _selectedDate = HealthMetricItem.normalizeDate(DateTime.now());
  bool _isSubmitting = false;

  bool get _selectedDateHasExistingValue =>
      widget.metric.recordForDate(_selectedDate) != null;

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

    if (selected != null) {
      setState(() {
        _selectedDate = HealthMetricItem.normalizeDate(selected);
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

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
    } catch (error) {
      if (mounted) {
        showAppErrorSnackBarForException(
          context,
          error,
          fallbackMessage: 'Не удалось сохранить значение метрики.',
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
    final visuals = MetricVisualPalette.fromStyle(widget.metric.visualStyle);

    return AppFormSheet(
      title: 'Записать ${widget.metric.title}',
      busy: _isSubmitting,
      subtitle: Text(
        'Нормальный диапазон: '
        '${_formatMetricNumber(widget.metric.targetMin)}-'
        '${_formatMetricNumber(widget.metric.targetMax)} ${widget.metric.unit}',
        style: const TextStyle(
          color: Color(0xFF8DA2C0),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: visuals.iconBackground,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(visuals.icon, color: visuals.accentColor, size: 48),
              ),
            ),
            const SizedBox(height: 28),
            AppTextField(
              label: '',
              hintText: 'Введите ${widget.metric.unit}',
              controller: _valueController,
              accentColor: visuals.accentColor,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: visuals.accentColor,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
              hintStyle: TextStyle(
                color: visuals.accentColor.withValues(alpha: 0.45),
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 24,
              ),
              borderRadius: 24,
              validator: (value) =>
                  decimalNumberValidator(value, message: 'Введите значение'),
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
            AppPickerField(
              label: 'Дата',
              text: formatLongMonthDate(_selectedDate),
              placeholder: 'dd.MM.yyyy',
              onTap: _isSubmitting ? null : _pickDate,
              accentColor: visuals.accentColor,
              suffixIcon: const Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFF8FA1BC),
                size: 20,
              ),
            ),
            if (_selectedDateHasExistingValue) ...[
              const SizedBox(height: 10),
              const Text(
                'На эту дату уже есть сохраненное значение. При сохранении оно будет заменено.',
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
              child: AppBusyFilledButton(
                busy: _isSubmitting,
                label: 'Сохранить значение',
                color: visuals.accentColor,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMetricNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  final singleDecimal = value.toStringAsFixed(1);
  return double.parse(singleDecimal) == value
      ? singleDecimal
      : value.toStringAsFixed(2);
}
