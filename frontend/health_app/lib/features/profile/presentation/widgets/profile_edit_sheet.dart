import 'package:flutter/material.dart';

import '../../../../core/widgets/app_form_sheet.dart';
import '../../domain/entities/user_profile.dart';

Future<void> showProfileEditSheet({
  required BuildContext context,
  required UserProfile initialProfile,
  required Future<void> Function(UserProfile profile) onSubmit,
}) {
  return showAppModalSheet<void>(
    context: context,
    heightFactor: 0.92,
    builder: (_) =>
        ProfileEditSheet(initialProfile: initialProfile, onSubmit: onSubmit),
  );
}

class ProfileEditSheet extends StatefulWidget {
  const ProfileEditSheet({
    super.key,
    required this.initialProfile,
    required this.onSubmit,
  });

  final UserProfile initialProfile;
  final Future<void> Function(UserProfile profile) onSubmit;

  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _fullNameController = TextEditingController(
    text: widget.initialProfile.fullName,
  );
  late final _emailController = TextEditingController(
    text: widget.initialProfile.email,
  );
  late final _ageController = TextEditingController(
    text: widget.initialProfile.age?.toString() ?? '',
  );
  late final _bloodTypeController = TextEditingController(
    text: widget.initialProfile.bloodType ?? '',
  );
  late final _heightController = TextEditingController(
    text: widget.initialProfile.heightCm?.toString() ?? '',
  );
  late final _weightController = TextEditingController(
    text: widget.initialProfile.weightKg?.toString() ?? '',
  );
  late final _primaryDoctorController = TextEditingController(
    text: widget.initialProfile.primaryDoctor ?? '',
  );
  late final _emergencyContactNameController = TextEditingController(
    text: widget.initialProfile.emergencyContactName ?? '',
  );
  late final _emergencyContactDetailsController = TextEditingController(
    text: widget.initialProfile.emergencyContactDetails ?? '',
  );
  late ProfileGender _gender = widget.initialProfile.gender;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _bloodTypeController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _primaryDoctorController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactDetailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final profile = widget.initialProfile.copyWith(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        gender: _gender,
        age: _tryParseInt(_ageController.text),
        bloodType: _normalizeText(_bloodTypeController.text),
        heightCm: _tryParseInt(_heightController.text),
        weightKg: _tryParseDouble(_weightController.text),
        primaryDoctor: _normalizeText(_primaryDoctorController.text),
        emergencyContactName: _normalizeText(
          _emergencyContactNameController.text,
        ),
        emergencyContactDetails: _normalizeText(
          _emergencyContactDetailsController.text,
        ),
        updatedAt: DateTime.now(),
      );
      await widget.onSubmit(profile);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить профиль.')),
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
      title: 'Редактировать профиль',
      busy: _isSubmitting,
      bodySpacing: 24,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Имя и фамилия',
              hintText: 'например, Иван Петров',
              controller: _fullNameController,
              accentColor: const Color(0xFF18B552),
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'E-mail',
              hintText: 'например, ivan@email.com',
              controller: _emailController,
              accentColor: const Color(0xFF18B552),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 18),
            const AppFieldLabel('Пол'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _GenderChip(
                  label: 'Мужской',
                  selected: _gender == ProfileGender.male,
                  onTap: () => setState(() => _gender = ProfileGender.male),
                ),
                _GenderChip(
                  label: 'Женский',
                  selected: _gender == ProfileGender.female,
                  onTap: () => setState(() => _gender = ProfileGender.female),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Возраст',
                    hintText: '20',
                    controller: _ageController,
                    accentColor: const Color(0xFF18B552),
                    keyboardType: TextInputType.number,
                    validator: _optionalPositiveIntValidator,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AppTextField(
                    label: 'Группа крови',
                    hintText: 'A+',
                    controller: _bloodTypeController,
                    accentColor: const Color(0xFF18B552),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Рост (см)',
                    hintText: '180',
                    controller: _heightController,
                    accentColor: const Color(0xFF18B552),
                    keyboardType: TextInputType.number,
                    validator: _optionalPositiveIntValidator,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AppTextField(
                    label: 'Вес (кг)',
                    hintText: '80',
                    controller: _weightController,
                    accentColor: const Color(0xFF18B552),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _optionalPositiveDoubleValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Основной врач',
              hintText: 'например, д-р Иван Петров',
              controller: _primaryDoctorController,
              accentColor: const Color(0xFF18B552),
            ),
            const SizedBox(height: 18),
            const AppFieldLabel('Экстренный контакт'),
            const SizedBox(height: 12),
            AppTextField(
              label: '',
              hintText: 'Имя контакта',
              controller: _emergencyContactNameController,
              accentColor: const Color(0xFF18B552),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: '',
              hintText: 'Телефон, Telegram или другой способ связи',
              controller: _emergencyContactDetailsController,
              accentColor: const Color(0xFF18B552),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: AppBusyFilledButton(
                busy: _isSubmitting,
                label: 'Сохранить профиль',
                color: const Color(0xFF18B552),
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _optionalPositiveIntValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null) {
      return 'Введите число';
    }
    return parsed > 0 ? null : 'Значение должно быть больше нуля';
  }

  String? _optionalPositiveDoubleValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
    if (parsed == null) {
      return 'Введите число';
    }
    return parsed > 0 ? null : 'Значение должно быть больше нуля';
  }

  int? _tryParseInt(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : int.tryParse(trimmed);
  }

  double? _tryParseDouble(String value) {
    final trimmed = value.trim().replaceAll(',', '.');
    return trimmed.isEmpty ? null : double.tryParse(trimmed);
  }

  String? _normalizeText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppChoiceChip(
      label: label,
      selected: selected,
      onTap: onTap,
      selectedColor: const Color(0xFF18B552),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }
}
