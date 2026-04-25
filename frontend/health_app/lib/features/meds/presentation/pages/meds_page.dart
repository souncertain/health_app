import 'package:flutter/material.dart';

import '../../../../core/layout/app_layout_constants.dart';
import '../../domain/entities/medication_item.dart';
import '../../domain/entities/upcoming_reminder.dart';

class MedsPage extends StatefulWidget {
  const MedsPage({super.key});

  @override
  State<MedsPage> createState() => _MedsPageState();
}

class _MedsPageState extends State<MedsPage> {
  int _selectedDayIndex = 3;

  final List<_MedsDayData> _days = const [
    _MedsDayData(shortLabel: 'M', dayNumber: '9'),
    _MedsDayData(shortLabel: 'T', dayNumber: '10'),
    _MedsDayData(shortLabel: 'W', dayNumber: '11'),
    _MedsDayData(shortLabel: 'T', dayNumber: '12'),
    _MedsDayData(shortLabel: 'F', dayNumber: '13'),
    _MedsDayData(shortLabel: 'S', dayNumber: '14'),
    _MedsDayData(shortLabel: 'S', dayNumber: '15'),
  ];

  final List<MedicationItem> _medications = const [
    MedicationItem(
      name: 'Lisinopril',
      dosage: '10mg',
      frequency: 'Once daily',
      times: ['08:00 AM'],
      status: MedicationStatus.taken,
      form: MedicationForm.capsule,
      notificationsEnabled: true,
      completed: true,
    ),
    MedicationItem(
      name: 'Metformin',
      dosage: '500mg',
      frequency: 'Twice daily',
      times: ['08:00 AM', '08:00 PM'],
      status: MedicationStatus.pending,
      form: MedicationForm.syringe,
      notificationsEnabled: true,
    ),
    MedicationItem(
      name: 'Atorvastatin',
      dosage: '20mg',
      frequency: 'Once daily',
      times: ['10:00 PM'],
      status: MedicationStatus.missed,
      form: MedicationForm.circle,
      notificationsEnabled: false,
    ),
    MedicationItem(
      name: 'Aspirin',
      dosage: '100mg',
      frequency: 'Once daily',
      times: ['07:00 AM'],
      status: MedicationStatus.taken,
      form: MedicationForm.tablet,
      notificationsEnabled: true,
      completed: true,
    ),
  ];

  final List<UpcomingReminder> _reminders = const [
    UpcomingReminder(name: 'Metformin', dosage: '500mg', time: '08:00 PM'),
    UpcomingReminder(name: 'Atorvastatin', dosage: '20mg', time: '10:00 PM'),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 390;
    final horizontalPadding = isCompact ? 16.0 : 20.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEFFBF2), Color(0xFFF8FFFA)],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MedsHeader(
                    isCompact: isCompact,
                    days: _days,
                    selectedDayIndex: _selectedDayIndex,
                    onDaySelected: (index) {
                      setState(() {
                        _selectedDayIndex = index;
                      });
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      24,
                      horizontalPadding,
                      0,
                    ),
                    child: Column(
                      children: _medications
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: _MedicationCard(
                                item: item,
                                compact: isCompact,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      2,
                      horizontalPadding,
                      0,
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          child: _MedicationSummaryCard(
                            value: '2',
                            label: 'Taken Today',
                            background: Color(0xFFDDF8E5),
                            valueColor: Color(0xFF11A648),
                            labelColor: Color(0xFF11A648),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: _MedicationSummaryCard(
                            value: '1',
                            label: 'Remaining',
                            background: Color(0xFFFFF2B8),
                            valueColor: Color(0xFFF59E0B),
                            labelColor: Color(0xFFF59E0B),
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: _MedicationSummaryCard(
                            value: '1',
                            label: 'Missed',
                            background: Color(0xFFFFDCDD),
                            valueColor: Color(0xFFEF4444),
                            labelColor: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      28,
                      horizontalPadding,
                      12,
                    ),
                    child: Text(
                      'Upcoming Reminders',
                      style: TextStyle(
                        fontSize: isCompact ? 20 : 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0C1C46),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      0,
                    ),
                    child: Column(
                      children: _reminders
                          .map(
                            (reminder) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _UpcomingReminderCard(reminder: reminder),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      10,
                      horizontalPadding,
                      kPageBottomOverlayPadding,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF18A8CC),
                          foregroundColor: Colors.white,
                          elevation: 10,
                          shadowColor: const Color(
                            0xFF18A8CC,
                          ).withValues(alpha: 0.28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: isCompact ? 18 : 21,
                          ),
                        ),
                        icon: Icon(
                          Icons.add_rounded,
                          size: isCompact ? 26 : 30,
                        ),
                        label: Text(
                          'Add Medication',
                          style: TextStyle(
                            fontSize: isCompact ? 16 : 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedsHeader extends StatelessWidget {
  const _MedsHeader({
    required this.isCompact,
    required this.days,
    required this.selectedDayIndex,
    required this.onDaySelected,
  });

  final bool isCompact;
  final List<_MedsDayData> days;
  final int selectedDayIndex;
  final ValueChanged<int> onDaySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFF18A8CC)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 16 : 20,
          24,
          isCompact ? 16 : 20,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thursday, April 16',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: isCompact ? 15 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Medications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 28 : 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.medication_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Today's Progress",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '2/4 taken',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 0.5,
                      minHeight: 12,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF62E09D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: List.generate(days.length, (index) {
                final day = days[index];
                final selected = index == selectedDayIndex;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == days.length - 1 ? 0 : 8,
                    ),
                    child: GestureDetector(
                      onTap: () => onDaySelected(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              day.shortLabel,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFF0E8DB0)
                                    : Colors.white.withValues(alpha: 0.78),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              day.dayNumber,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFF0E8DB0)
                                    : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF0E8DB0)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.item, required this.compact});

  final MedicationItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = _MedicationCardPalette.fromStatus(item.status);
    final timeBackground = _timeBackground(item.status);
    final timeTextColor = _timeTextColor(item.status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 20,
        vertical: compact ? 18 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD5EFD9).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: palette.iconBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(
                _iconForForm(item.form),
                color: palette.iconColor,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          decoration: item.completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: const Color(0xFF0C1C46),
                          fontSize: compact ? 18 : 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (item.status == MedicationStatus.missed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE1E1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'MISSED',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.dosage} - ${item.frequency}',
                  style: TextStyle(
                    color: const Color(0xFF5B7397),
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: item.times
                      .map(
                        (time) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: timeBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 16,
                                color: timeTextColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                time,
                                style: TextStyle(
                                  color: timeTextColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Icon(
                item.notificationsEnabled
                    ? Icons.notifications_none_rounded
                    : Icons.notifications_off_outlined,
                color: item.notificationsEnabled
                    ? const Color(0xFF12A64A)
                    : const Color(0xFF9DAECC),
                size: 24,
              ),
              const SizedBox(height: 22),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.trailingBackground,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    palette.trailingIcon,
                    color: palette.trailingIconColor,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForForm(MedicationForm form) {
    switch (form) {
      case MedicationForm.capsule:
        return Icons.medication_rounded;
      case MedicationForm.syringe:
        return Icons.vaccines_rounded;
      case MedicationForm.tablet:
        return Icons.radio_button_unchecked_rounded;
      case MedicationForm.circle:
        return Icons.circle_rounded;
    }
  }

  Color _timeBackground(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.taken:
        return const Color(0xFFE6FBEA);
      case MedicationStatus.pending:
        return const Color(0xFFE5EEFF);
      case MedicationStatus.missed:
        return const Color(0xFFF1E8FF);
    }
  }

  Color _timeTextColor(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.taken:
        return const Color(0xFF12A64A);
      case MedicationStatus.pending:
        return const Color(0xFF3165E6);
      case MedicationStatus.missed:
        return const Color(0xFF7C3AED);
    }
  }
}

class _MedicationCardPalette {
  const _MedicationCardPalette({
    required this.borderColor,
    required this.iconBackground,
    required this.iconColor,
    required this.trailingBackground,
    required this.trailingIcon,
    required this.trailingIconColor,
  });

  final Color borderColor;
  final Color iconBackground;
  final Color iconColor;
  final Color trailingBackground;
  final IconData trailingIcon;
  final Color trailingIconColor;

  factory _MedicationCardPalette.fromStatus(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.taken:
        return const _MedicationCardPalette(
          borderColor: Color(0xFFF0F6F1),
          iconBackground: Color(0xFFDDF8E5),
          iconColor: Color(0xFF12A64A),
          trailingBackground: Color(0xFFDDF8E5),
          trailingIcon: Icons.check_circle_outline_rounded,
          trailingIconColor: Color(0xFF12A64A),
        );
      case MedicationStatus.pending:
        return const _MedicationCardPalette(
          borderColor: Color(0xFFF0F4FB),
          iconBackground: Color(0xFFE0ECFF),
          iconColor: Color(0xFF3165E6),
          trailingBackground: Color(0xFFF1F5FB),
          trailingIcon: Icons.radio_button_unchecked_rounded,
          trailingIconColor: Color(0xFFC9D4E6),
        );
      case MedicationStatus.missed:
        return const _MedicationCardPalette(
          borderColor: Color(0xFFFFD0D0),
          iconBackground: Color(0xFFF1E8FF),
          iconColor: Color(0xFF2D8BE6),
          trailingBackground: Color(0xFFF1F5FB),
          trailingIcon: Icons.radio_button_unchecked_rounded,
          trailingIconColor: Color(0xFFC9D4E6),
        );
    }
  }
}

class _MedicationSummaryCard extends StatelessWidget {
  const _MedicationSummaryCard({
    required this.value,
    required this.label,
    required this.background,
    required this.valueColor,
    required this.labelColor,
  });

  final String value;
  final String label;
  final Color background;
  final Color valueColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingReminderCard extends StatelessWidget {
  const _UpcomingReminderCard({required this.reminder});

  final UpcomingReminder reminder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD5EFD9).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Color(0xFFE7FAEE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: Color(0xFF11A648),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.name,
                  style: const TextStyle(
                    color: Color(0xFF0C1C46),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reminder.dosage,
                  style: const TextStyle(
                    color: Color(0xFF90A4C4),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            reminder.time,
            style: const TextStyle(
              color: Color(0xFF11A648),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedsDayData {
  const _MedsDayData({required this.shortLabel, required this.dayNumber});

  final String shortLabel;
  final String dayNumber;
}
