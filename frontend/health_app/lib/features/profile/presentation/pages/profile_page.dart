import 'package:flutter/material.dart';

import '../../../../core/layout/app_layout_constants.dart';
import '../../../../core/services/local_notifications_service.dart';
import '../../data/datasources/profile_local_data_source.dart';
import '../../data/repositories/local_profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_edit_sheet.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.repository, required this.onSignOut});

  final ProfileRepository? repository;
  final Future<void> Function() onSignOut;

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  late final ProfileController _controller;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    final repository =
        widget.repository ?? LocalProfileRepository(ProfileLocalDataSource());
    _controller = ProfileController(
      repository: repository,
      notifications: LocalNotificationsService.instance,
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> refreshProfile() {
    return _controller.refresh();
  }

  Future<void> _openEditSheet() {
    return showProfileEditSheet(
      context: context,
      initialProfile: _controller.profile,
      onSubmit: _controller.saveProfile,
    );
  }

  Future<void> _signOut() async {
    final shouldSignOut =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Выйти из аккаунта?'),
              content: const Text(
                'Мы завершим текущую сессию и очистим локальные данные этого пользователя на устройстве.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Выйти'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldSignOut || _isSigningOut) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    try {
      await widget.onSignOut();
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEFFBF3), Color(0xFFF9FFFB)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            if (_controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF18B552)),
              );
            }

            final profile = _controller.profile;
            final stats = _controller.stats;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                18,
                16,
                18,
                52 + kPageBottomOverlayPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(profile: profile, onEdit: _openEditSheet),
                  const SizedBox(height: 14),
                  _StatsRow(stats: stats),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Сводка здоровья',
                    titleColor: const Color(0xFF12203F),
                    children: [
                      _InfoRow(
                        icon: Icons.height_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        label: 'Рост',
                        value: profile.heightCm == null
                            ? 'Не указано'
                            : '${profile.heightCm} см',
                      ),
                      _InfoRow(
                        icon: Icons.monitor_weight_outlined,
                        iconColor: const Color(0xFF1595C9),
                        label: 'Вес',
                        value: profile.weightKg == null
                            ? 'Не указано'
                            : '${_formatWeight(profile.weightKg!)} кг',
                      ),
                      _InfoRow(
                        icon: Icons.favorite_rounded,
                        iconColor: const Color(0xFF22C55E),
                        label: 'ИМТ',
                        value: _buildBmiLabel(profile),
                      ),
                      _InfoRow(
                        icon: Icons.medical_services_outlined,
                        iconColor: const Color(0xFF7C3AED),
                        label: 'Основной врач',
                        value: _valueOrPlaceholder(profile.primaryDoctor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Медицинский профиль',
                    titleColor: const Color(0xFF18B552),
                    children: [
                      _InfoRow(
                        icon: Icons.bloodtype_outlined,
                        iconColor: const Color(0xFFEF4444),
                        label: 'Группа крови',
                        value: _valueOrPlaceholder(profile.bloodType),
                      ),
                      _EmergencyContactRow(profile: profile),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Настройки приложения',
                    titleColor: const Color(0xFF1595C9),
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEAFBF0),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFF18B552),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Уведомления',
                                  style: TextStyle(
                                    color: Color(0xFF12203F),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Препараты и визиты',
                                  style: TextStyle(
                                    color: Color(0xFF8FA1BC),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: profile.notificationsEnabled,
                            onChanged: _controller.isSaving
                                ? null
                                : _controller.toggleNotifications,
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFF18B552),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSigningOut ? null : _signOut,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFC0392B),
                        side: BorderSide(
                          color: const Color(
                            0xFFC0392B,
                          ).withValues(alpha: 0.28),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                      ),
                      icon: _isSigningOut
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout_rounded, size: 20),
                      label: Text(
                        _isSigningOut ? 'Выходим...' : 'Выйти из аккаунта',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'HealthTrack v2.4.1',
                      style: TextStyle(
                        color: const Color(0xFF8FA1BC).withValues(alpha: 0.88),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _valueOrPlaceholder(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? 'Не указано' : trimmed;
  }

  String _formatWeight(double weight) {
    return weight.truncateToDouble() == weight
        ? weight.toStringAsFixed(0)
        : weight.toStringAsFixed(1);
  }

  String _buildBmiLabel(UserProfile profile) {
    final bmi = profile.bmi;
    if (bmi == null) {
      return 'Не указано';
    }
    final label = bmi < 18.5
        ? 'Ниже нормы'
        : bmi < 25
        ? 'Норма'
        : bmi < 30
        ? 'Выше нормы'
        : 'Высокий';
    return '${bmi.toStringAsFixed(1)} · $label';
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onEdit});

  final UserProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final chips = <String>[
      if (profile.gender != ProfileGender.unspecified)
        profile.gender.displayLabel,
      if (profile.age != null) '${profile.age} лет',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18B552),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2618B552),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Мой профиль',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: onEdit,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text(
                  'Изменить',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  profile.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName.trim().isEmpty
                          ? 'Пользователь'
                          : profile.fullName.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email.trim().isEmpty
                          ? 'Добавьте e-mail'
                          : profile.email.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13.5,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: chips
                            .map((chip) => _ProfileChip(label: chip))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        icon: Icons.favorite_rounded,
        value: stats.bpReadingsCount.toString(),
        label: 'Давление',
        iconColor: const Color(0xFFEF4444),
      ),
      _StatItem(
        icon: Icons.medication_rounded,
        value: stats.medicationsCount.toString(),
        label: 'Препараты',
        iconColor: const Color(0xFF1595C9),
      ),
      _StatItem(
        icon: Icons.calendar_month_rounded,
        value: stats.appointmentsCount.toString(),
        label: 'Визиты',
        iconColor: const Color(0xFFEB8A06),
      ),
      _StatItem(
        icon: Icons.emoji_events_rounded,
        value: stats.daysTracked.toString(),
        label: 'Дни',
        iconColor: const Color(0xFF7C3AED),
      ),
    ];

    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Expanded(child: _StatCard(item: items[index])),
          if (index < items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120C1C46),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            item.value,
            style: TextStyle(
              color: item.iconColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8FA1BC),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.titleColor,
    required this.children,
  });

  final String title;
  final Color titleColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120C1C46),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: titleColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.35,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF61738F),
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.topRight,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: Color(0xFF12203F),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactRow extends StatelessWidget {
  const _EmergencyContactRow({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final hasContact =
        (profile.emergencyContactName?.trim().isNotEmpty ?? false) ||
        (profile.emergencyContactDetails?.trim().isNotEmpty ?? false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.emergency_outlined,
              color: Color(0xFF8B5CF6),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const SizedBox(
            width: 112,
            child: Text(
              'Экстренный контакт',
              style: TextStyle(
                color: Color(0xFF61738F),
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.topRight,
              child: hasContact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if ((profile.emergencyContactName?.trim().isNotEmpty ??
                            false))
                          Text(
                            profile.emergencyContactName!.trim(),
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: Color(0xFF12203F),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        if ((profile.emergencyContactDetails
                                ?.trim()
                                .isNotEmpty ??
                            false))
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              profile.emergencyContactDetails!.trim(),
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                color: Color(0xFF8FA1BC),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    )
                  : const Text(
                      'Не указано',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Color(0xFF12203F),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on ProfileGender {
  String get displayLabel {
    switch (this) {
      case ProfileGender.male:
        return 'Мужской';
      case ProfileGender.female:
        return 'Женский';
      case ProfileGender.unspecified:
        return 'Не указано';
    }
  }
}
