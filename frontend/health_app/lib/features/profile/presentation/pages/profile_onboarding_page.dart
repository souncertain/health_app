import 'package:flutter/material.dart';

import '../../../../core/ui/app_error_feedback.dart';
import '../../../../core/widgets/app_form_sheet.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../controllers/profile_onboarding_controller.dart';

class ProfileOnboardingPage extends StatefulWidget {
  const ProfileOnboardingPage({
    super.key,
    required this.initialProfile,
    required this.repository,
    required this.onSkipped,
    required this.onCompleted,
  });

  final UserProfile initialProfile;
  final ProfileRepository repository;
  final Future<void> Function() onSkipped;
  final Future<void> Function() onCompleted;

  @override
  State<ProfileOnboardingPage> createState() => _ProfileOnboardingPageState();
}

class _ProfileOnboardingPageState extends State<ProfileOnboardingPage> {
  late final ProfileOnboardingController _controller = ProfileOnboardingController(
    repository: widget.repository,
    initialProfile: widget.initialProfile,
  );

  final _personalInfoFormKey = GlobalKey<FormState>();
  final _healthInfoFormKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  DateTime? _selectedBirthday;
  ProfileGender _selectedGender = ProfileGender.unspecified;
  String? _selectedBloodType;
  bool _showPersonalInfoValidation = false;

  @override
  void initState() {
    super.initState();
    final (firstName, lastName) = _splitFullName(widget.initialProfile.fullName);
    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _phoneController = TextEditingController(text: widget.initialProfile.phone);
    _heightController = TextEditingController(
      text: widget.initialProfile.heightCm?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.initialProfile.weightKg == null
          ? ''
          : _formatWeight(widget.initialProfile.weightKg!),
    );
    _selectedBirthday =
        widget.initialProfile.birthDate ??
        _birthdayFromAge(widget.initialProfile.age);
    _selectedGender = widget.initialProfile.gender;
    _selectedBloodType = ProfileOnboardingController.localizedBloodTypeFromCanonical(
      widget.initialProfile.bloodType,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _handleSkip() async {
    if (_controller.isSaving) {
      return;
    }

    try {
      await widget.onSkipped();
    } catch (error) {
      if (!mounted) {
        return;
      }

      showAppErrorSnackBarForException(
        context,
        error,
        fallbackMessage: 'Не удалось пропустить настройку профиля.',
      );
    }
  }

  Future<void> _continueFromPersonalInfo() async {
    setState(() => _showPersonalInfoValidation = true);
    final isFormValid = _personalInfoFormKey.currentState?.validate() ?? false;
    final hasBirthday = _selectedBirthday != null;
    final hasGender = _selectedGender != ProfileGender.unspecified;

    if (!isFormValid || !hasBirthday || !hasGender) {
      return;
    }

    _controller.nextToHealthInfo();
  }

  Future<void> _finishOnboarding({bool saveOptionalStep = true}) async {
    setState(() => _showPersonalInfoValidation = true);
    final isPersonalInfoValid =
        (_personalInfoFormKey.currentState?.validate() ?? false) &&
        _selectedBirthday != null &&
        _selectedGender != ProfileGender.unspecified;
    if (!isPersonalInfoValid) {
      _controller.start();
      return;
    }

    if (saveOptionalStep &&
        !(_healthInfoFormKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      await _controller.complete(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        birthday: _selectedBirthday!,
        gender: _selectedGender,
        phone: _phoneController.text.trim(),
        heightCm: _tryParseInt(_heightController.text),
        weightKg: _tryParseDouble(_weightController.text),
        localizedBloodType: _selectedBloodType,
      );
      await widget.onCompleted();
    } catch (error) {
      if (!mounted) {
        return;
      }

      showAppErrorSnackBarForException(
        context,
        error,
        fallbackMessage: 'Не удалось сохранить данные профиля.',
      );
    }
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initialDate =
        _selectedBirthday ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('ru'),
      initialDate: initialDate,
      firstDate: DateTime(now.year - 130, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Дата рождения',
      cancelText: 'Отмена',
      confirmText: 'Выбрать',
    );

    if (picked == null) {
      return;
    }

    setState(() => _selectedBirthday = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF2FCF4),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF4FCF5), Color(0xFFEAF9EF)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  right: -80,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF95F0AF).withValues(alpha: 0.16),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: switch (_controller.step) {
                      ProfileOnboardingStep.welcome => _buildWelcomeStep(),
                      ProfileOnboardingStep.personalInfo => _buildPersonalInfoStep(),
                      ProfileOnboardingStep.healthInfo => _buildHealthInfoStep(),
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeStep() {
    return SingleChildScrollView(
      key: const ValueKey('onboarding-welcome'),
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height - MediaQuery.paddingOf(context).top - 60,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 36),
            Container(
              width: 138,
              height: 138,
              decoration: BoxDecoration(
                color: const Color(0xFF1DB954),
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.26),
                    blurRadius: 34,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),
            const SizedBox(height: 34),
            const Text(
              'Добро пожаловать\nв HealthTrack!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF166B3C),
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.18,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Давайте настроим приложение под вас за пару шагов. Это займет не больше минуты.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF5D8A67),
                fontSize: 18,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _controller.isSaving ? null : _controller.start,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 10,
                  shadowColor: const Color(0xFF1DB954).withValues(alpha: 0.24),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Начать',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, size: 26),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: _handleSkip,
              child: const Text(
                'Сделаю позже',
                style: TextStyle(
                  color: Color(0xFF7BD69A),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 34),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _WelcomeStageItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Личные данные',
                ),
                _WelcomeStageItem(
                  icon: Icons.favorite_outline_rounded,
                  label: 'Здоровье',
                ),
                _WelcomeStageItem(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Готово',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    final birthdayError = _showPersonalInfoValidation && _selectedBirthday == null;
    final genderError =
        _showPersonalInfoValidation && _selectedGender == ProfileGender.unspecified;

    return SingleChildScrollView(
      key: const ValueKey('onboarding-personal'),
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            stepLabel: 'Шаг 1 из 2',
            progress: 0.5,
            onSkip: _handleSkip,
          ),
          const SizedBox(height: 30),
          const Text(
            'Расскажите\nо себе',
            style: TextStyle(
              color: Color(0xFF166B3C),
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Это поможет персонализировать приложение и сделать рекомендации точнее.',
            style: TextStyle(
              color: Color(0xFF5D8A67),
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          Form(
            key: _personalInfoFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Имя *',
                  hintText: 'Введите имя',
                  controller: _firstNameController,
                  accentColor: const Color(0xFF1DB954),
                  validator: _requiredTextValidator,
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Фамилия *',
                  hintText: 'Введите фамилию',
                  controller: _lastNameController,
                  accentColor: const Color(0xFF1DB954),
                  validator: _requiredTextValidator,
                ),
                const SizedBox(height: 18),
                AppPickerField(
                  label: 'Дата рождения *',
                  placeholder: 'дд.мм.гггг',
                  text: _selectedBirthday == null
                      ? null
                      : _formatDate(_selectedBirthday!),
                  accentColor: const Color(0xFF1DB954),
                  onTap: _pickBirthday,
                  suffixIcon: const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF7BD69A),
                    size: 22,
                  ),
                ),
                if (birthdayError) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Выберите дату рождения',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                const AppFieldLabel('Пол *'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SelectionCard(
                        label: 'Мужской',
                        icon: Icons.male_rounded,
                        selected: _selectedGender == ProfileGender.male,
                        onTap: () => setState(
                          () => _selectedGender = ProfileGender.male,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SelectionCard(
                        label: 'Женский',
                        icon: Icons.female_rounded,
                        selected: _selectedGender == ProfileGender.female,
                        onTap: () => setState(
                          () => _selectedGender = ProfileGender.female,
                        ),
                      ),
                    ),
                  ],
                ),
                if (genderError) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Выберите пол',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _controller.isSaving ? null : _continueFromPersonalInfo,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFDCE7DF),
                disabledForegroundColor: const Color(0xFFAEBBB1),
                padding: const EdgeInsets.symmetric(vertical: 22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 10,
                shadowColor: const Color(0xFF1DB954).withValues(alpha: 0.18),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Продолжить',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, size: 26),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: _controller.isSaving ? null : _controller.goBack,
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text(
                'Назад',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7BD69A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthInfoStep() {
    return SingleChildScrollView(
      key: const ValueKey('onboarding-health'),
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 28),
      child: Form(
        key: _healthInfoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeader(
              stepLabel: 'Шаг 2 из 2',
              progress: 1,
              onSkip: () => _finishOnboarding(saveOptionalStep: false),
            ),
            const SizedBox(height: 30),
            const Text(
              'Данные\nо здоровье',
              style: TextStyle(
                color: Color(0xFF166B3C),
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Необязательно — можно пропустить любое поле, которое вы пока не хотите заполнять.',
              style: TextStyle(
                color: Color(0xFF5D8A67),
                fontSize: 18,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            AppTextField(
              label: 'Телефон',
              hintText: '+7 (999) 123-45-67',
              controller: _phoneController,
              accentColor: const Color(0xFF1DB954),
              keyboardType: TextInputType.phone,
              validator: _optionalPhoneValidator,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Рост',
                    hintText: '180 см',
                    controller: _heightController,
                    accentColor: const Color(0xFF1DB954),
                    keyboardType: TextInputType.number,
                    validator: _optionalHeightValidator,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AppTextField(
                    label: 'Вес',
                    hintText: '75 кг',
                    controller: _weightController,
                    accentColor: const Color(0xFF1DB954),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: _optionalWeightValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const AppFieldLabel('Группа крови'),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ProfileOnboardingController.localizedBloodTypes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.16,
              ),
              itemBuilder: (context, index) {
                final bloodType =
                    ProfileOnboardingController.localizedBloodTypes[index];
                return _BloodTypeCard(
                  label: bloodType,
                  selected: _selectedBloodType == bloodType,
                  onTap: () => setState(() {
                    _selectedBloodType = _selectedBloodType == bloodType
                        ? null
                        : bloodType;
                  }),
                );
              },
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEAFBF0),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD5F1DE)),
              ),
              child: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Зачем это нужно: ',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text:
                          'эти данные помогают точнее рассчитывать показатели и персонализировать рекомендации. При желании вы сможете изменить их позже в профиле.',
                    ),
                  ],
                ),
                style: TextStyle(
                  color: Color(0xFF3F7A4E),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _controller.isSaving ? null : _finishOnboarding,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1DB954),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 10,
                  shadowColor: const Color(0xFF1DB954).withValues(alpha: 0.18),
                ),
                child: _controller.isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Завершить',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, size: 26),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: _controller.isSaving ? null : _controller.goBack,
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text(
                  'Назад',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF7BD69A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredTextValidator(String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return 'Заполните поле';
    }

    return null;
  }

  String? _optionalPhoneValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (!trimmed.startsWith('+7') || digits.length != 11) {
      return 'Введите телефон в формате +7 (999) 123-45-67';
    }

    return null;
  }

  String? _optionalHeightValidator(String? value) {
    final parsed = _tryParseInt(value ?? '');
    if ((value?.trim() ?? '').isEmpty) {
      return null;
    }
    if (parsed == null) {
      return 'Введите число';
    }
    if (parsed < 30 || parsed > 300) {
      return 'Рост должен быть от 30 до 300 см';
    }
    return null;
  }

  String? _optionalWeightValidator(String? value) {
    final parsed = _tryParseDouble(value ?? '');
    if ((value?.trim() ?? '').isEmpty) {
      return null;
    }
    if (parsed == null) {
      return 'Введите число';
    }
    if (parsed < 1 || parsed > 700) {
      return 'Вес должен быть от 1 до 700 кг';
    }
    return null;
  }

  int? _tryParseInt(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (trimmed.isEmpty) {
      return null;
    }

    return int.tryParse(trimmed);
  }

  double? _tryParseDouble(String value) {
    final trimmed = value
        .trim()
        .replaceAll('кг', '',)
        .replaceAll(' ', '')
        .replaceAll(',', '.');
    if (trimmed.isEmpty) {
      return null;
    }

    return double.tryParse(trimmed);
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
  }

  String _formatWeight(double value) {
    return value.truncateToDouble() == value
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  DateTime? _birthdayFromAge(int? age) {
    if (age == null || age <= 0) {
      return null;
    }

    final now = DateTime.now();
    return DateTime(now.year - age, now.month, now.day);
  }

  (String, String) _splitFullName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return ('', '');
    }
    if (parts.length == 1) {
      return (parts.first, '');
    }

    return (parts.first, parts.sublist(1).join(' '));
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.stepLabel,
    required this.progress,
    required this.onSkip,
  });

  final String stepLabel;
  final double progress;
  final Future<void> Function() onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                stepLabel,
                style: const TextStyle(
                  color: Color(0xFF5B873B),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: onSkip,
              child: const Text(
                'Пропустить пока',
                style: TextStyle(
                  color: Color(0xFF7BD69A),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: const Color(0xFFDDF5E4),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
          ),
        ),
      ],
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
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
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF1DB954) : const Color(0xFFD9F1E1),
            width: selected ? 2.2 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1DB954).withValues(alpha: selected ? 0.12 : 0.04),
              blurRadius: selected ? 18 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF1DB954) : const Color(0xFF67906B),
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(0xFF166B3C) : const Color(0xFF567E5A),
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BloodTypeCard extends StatelessWidget {
  const _BloodTypeCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1DB954) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF1DB954) : const Color(0xFFD9F1E1),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF4F7C55),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _WelcomeStageItem extends StatelessWidget {
  const _WelcomeStageItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFDDF7E4),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(icon, color: const Color(0xFF20B456), size: 30),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 92,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7BD69A),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
