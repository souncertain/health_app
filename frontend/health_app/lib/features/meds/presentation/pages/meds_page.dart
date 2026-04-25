import 'package:flutter/material.dart';

import '../../../../core/layout/app_layout_constants.dart';
import '../../data/datasources/medication_local_data_source.dart';
import '../../data/repositories/local_medication_repository.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';
import '../../domain/usecases/delete_medication.dart';
import '../../domain/usecases/get_medications.dart';
import '../../domain/usecases/save_medication.dart';
import '../controllers/meds_controller.dart';
import '../widgets/medication_sheet.dart';

class MedsPage extends StatefulWidget {
  const MedsPage({super.key, this.repository});

  final MedicationRepository? repository;

  @override
  State<MedsPage> createState() => MedsPageState();
}

class MedsPageState extends State<MedsPage> {
  late final MedsController _controller;
  late final List<_MedsDayData> _days;
  late int _selectedDayIndex;

  int get _selectedWeekday => _days[_selectedDayIndex].weekday;
  DateTime get _selectedDate => _days[_selectedDayIndex].date;

  @override
  void initState() {
    super.initState();
    final repository =
        widget.repository ??
        LocalMedicationRepository(MedicationLocalDataSource());
    _controller = MedsController(
      getMedications: GetMedicationsUseCase(repository),
      saveMedication: SaveMedicationUseCase(repository),
      deleteMedication: DeleteMedicationUseCase(repository),
    );
    _days = _buildCurrentWeekDays(DateTime.now());
    _selectedDayIndex = DateTime.now().weekday - 1;
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> openCreateMedicationSheet() {
    return showMedicationSheet(
      context: context,
      selectedWeekday: _selectedWeekday,
      onSubmit: (value) {
        return _controller.saveMedication(
          name: value.name,
          dosage: value.dosage,
          baseTimeInMinutes: value.baseTimeInMinutes,
          frequency: value.frequency,
          notificationsEnabled: value.notificationsEnabled,
          selectedWeekday: value.selectedWeekday,
        );
      },
    );
  }

  Future<void> _openEditMedicationSheet(Medication medication) {
    return showMedicationSheet(
      context: context,
      selectedWeekday: _selectedWeekday,
      initialMedication: medication,
      onSubmit: (value) {
        return _controller.saveMedication(
          existingMedication: medication,
          name: value.name,
          dosage: value.dosage,
          baseTimeInMinutes: value.baseTimeInMinutes,
          frequency: value.frequency,
          notificationsEnabled: value.notificationsEnabled,
          selectedWeekday: value.selectedWeekday,
        );
      },
      onDelete: () => _controller.deleteMedication(medication),
    );
  }

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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final summary = _controller.summaryForDate(_selectedDate);
            final visibleMedications = _controller.medicationsForDate(
              _selectedDate,
            );
            final reminders = _controller.remindersForDate(_selectedDate);

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MedsHeader(
                            isCompact: isCompact,
                            days: _days,
                            selectedDayIndex: _selectedDayIndex,
                            progressValue: summary.progress,
                            takenCount: summary.taken,
                            totalCount: summary.total,
                            onDaySelected: (index) {
                              setState(() {
                                _selectedDayIndex = index;
                              });
                            },
                          ),
                          if (!_controller.hasMedications)
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                28,
                                horizontalPadding,
                                kPageBottomOverlayPadding,
                              ),
                              child: _EmptyMedicationState(
                                onPressed: openCreateMedicationSheet,
                              ),
                            )
                          else ...[
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                24,
                                horizontalPadding,
                                0,
                              ),
                              child: visibleMedications.isEmpty
                                  ? const _NoMedsForDayState()
                                  : Column(
                                      children: visibleMedications
                                          .map(
                                            (medication) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 18,
                                              ),
                                              child: _MedicationCard(
                                                medication: medication,
                                                status:
                                                    _controller.statusForDate(
                                                      medication,
                                                      _selectedDate,
                                                    ) ??
                                                    MedicationDayStatus.pending,
                                                compact: isCompact,
                                                onTap: () =>
                                                    _openEditMedicationSheet(
                                                      medication,
                                                    ),
                                                onNotificationTap: () {
                                                  _controller
                                                      .toggleNotifications(
                                                        medication,
                                                      );
                                                },
                                                onStatusTap: () {
                                                  _controller.toggleTakenStatus(
                                                    medication,
                                                    _selectedDate,
                                                  );
                                                },
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
                                children: [
                                  Expanded(
                                    child: _MedicationSummaryCard(
                                      value: '${summary.taken}',
                                      label: 'Taken',
                                      background: const Color(0xFFDDF8E5),
                                      valueColor: const Color(0xFF11A648),
                                      labelColor: const Color(0xFF11A648),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _MedicationSummaryCard(
                                      value: '${summary.pending}',
                                      label: 'Remaining',
                                      background: const Color(0xFFFFF2B8),
                                      valueColor: const Color(0xFFF59E0B),
                                      labelColor: const Color(0xFFF59E0B),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _MedicationSummaryCard(
                                      value: '${summary.missed}',
                                      label: 'Missed',
                                      background: const Color(0xFFFFDCDD),
                                      valueColor: const Color(0xFFEF4444),
                                      labelColor: const Color(0xFFEF4444),
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
                                'Upcoming Notifications',
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
                              child: reminders.isEmpty
                                  ? const _NoUpcomingRemindersState()
                                  : Column(
                                      children: reminders
                                          .map(
                                            (reminder) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: _UpcomingReminderCard(
                                                reminder: reminder,
                                              ),
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
                                  onPressed: openCreateMedicationSheet,
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
                        ],
                      ),
                    ),
                  ],
                ),
                if (_controller.isLoading && !_controller.hasMedications)
                  const Center(child: CircularProgressIndicator()),
              ],
            );
          },
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
    required this.progressValue,
    required this.takenCount,
    required this.totalCount,
    required this.onDaySelected,
  });

  final bool isCompact;
  final List<_MedsDayData> days;
  final int selectedDayIndex;
  final double progressValue;
  final int takenCount;
  final int totalCount;
  final ValueChanged<int> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final selectedDay = days[selectedDayIndex];

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
                        '${selectedDay.fullLabel}, ${selectedDay.monthDayLabel}',
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
                      Expanded(
                        child: Text(
                          'Progress for ${selectedDay.monthDayLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        totalCount == 0
                            ? '0/0 taken'
                            : '$takenCount/$totalCount taken',
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
                      value: progressValue,
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
                              '${day.dayNumber}',
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
  const _MedicationCard({
    required this.medication,
    required this.status,
    required this.compact,
    required this.onTap,
    required this.onNotificationTap,
    required this.onStatusTap,
  });

  final Medication medication;
  final MedicationDayStatus status;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onStatusTap;

  @override
  Widget build(BuildContext context) {
    final palette = _MedicationCardPalette.fromStatus(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
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
                    _iconForForm(medication.form),
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
                            medication.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              decoration: status == MedicationDayStatus.taken
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: const Color(0xFF0C1C46),
                              fontSize: compact ? 18 : 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (status == MedicationDayStatus.missed)
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
                      '${medication.dosage} - '
                      '${medicationFrequencyLabel(medication.frequency)}',
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
                      children: medication.timesInMinutes
                          .map(
                            (time) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: palette.timeBackground,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 16,
                                    color: palette.timeTextColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    formatMedicationTime(time),
                                    style: TextStyle(
                                      color: palette.timeTextColor,
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
                  IconButton(
                    onPressed: onNotificationTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                    splashRadius: 22,
                    icon: Icon(
                      medication.notificationsEnabled
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_off_outlined,
                      color: medication.notificationsEnabled
                          ? const Color(0xFF12A64A)
                          : const Color(0xFF9DAECC),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 22),
                  InkResponse(
                    onTap: onStatusTap,
                    radius: 28,
                    child: Container(
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
                  ),
                ],
              ),
            ],
          ),
        ),
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
}

class _MedicationCardPalette {
  const _MedicationCardPalette({
    required this.borderColor,
    required this.iconBackground,
    required this.iconColor,
    required this.timeBackground,
    required this.timeTextColor,
    required this.trailingBackground,
    required this.trailingIcon,
    required this.trailingIconColor,
  });

  final Color borderColor;
  final Color iconBackground;
  final Color iconColor;
  final Color timeBackground;
  final Color timeTextColor;
  final Color trailingBackground;
  final IconData trailingIcon;
  final Color trailingIconColor;

  factory _MedicationCardPalette.fromStatus(MedicationDayStatus status) {
    switch (status) {
      case MedicationDayStatus.taken:
        return const _MedicationCardPalette(
          borderColor: Color(0xFFF0F6F1),
          iconBackground: Color(0xFFDDF8E5),
          iconColor: Color(0xFF12A64A),
          timeBackground: Color(0xFFE6FBEA),
          timeTextColor: Color(0xFF12A64A),
          trailingBackground: Color(0xFFDDF8E5),
          trailingIcon: Icons.check_circle_outline_rounded,
          trailingIconColor: Color(0xFF12A64A),
        );
      case MedicationDayStatus.pending:
        return const _MedicationCardPalette(
          borderColor: Color(0xFFF0F4FB),
          iconBackground: Color(0xFFE0ECFF),
          iconColor: Color(0xFF3165E6),
          timeBackground: Color(0xFFE5EEFF),
          timeTextColor: Color(0xFF3165E6),
          trailingBackground: Color(0xFFF1F5FB),
          trailingIcon: Icons.radio_button_unchecked_rounded,
          trailingIconColor: Color(0xFFC9D4E6),
        );
      case MedicationDayStatus.missed:
        return const _MedicationCardPalette(
          borderColor: Color(0xFFFFD0D0),
          iconBackground: Color(0xFFF1E8FF),
          iconColor: Color(0xFF2D8BE6),
          timeBackground: Color(0xFFF1E8FF),
          timeTextColor: Color(0xFF7C3AED),
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

  final MedicationReminderPreview reminder;

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
            formatMedicationTime(reminder.timeInMinutes),
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

class _EmptyMedicationState extends StatelessWidget {
  const _EmptyMedicationState({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD5EFD9).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.medication_liquid_rounded,
            color: Color(0xFF18A8CC),
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'No medications added yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0C1C46),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Create your first medication schedule to track intake and notifications.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6F86A9),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF18A8CC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Medication',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMedsForDayState extends StatelessWidget {
  const _NoMedsForDayState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD5EFD9).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Text(
        'No medications are scheduled for this day.',
        style: TextStyle(
          color: Color(0xFF6F86A9),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NoUpcomingRemindersState extends StatelessWidget {
  const _NoUpcomingRemindersState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD5EFD9).withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Text(
        'No upcoming notifications for the selected day.',
        style: TextStyle(
          color: Color(0xFF90A4C4),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MedsDayData {
  const _MedsDayData({
    required this.date,
    required this.weekday,
    required this.shortLabel,
    required this.fullLabel,
    required this.dayNumber,
    required this.monthDayLabel,
  });

  final DateTime date;
  final int weekday;
  final String shortLabel;
  final String fullLabel;
  final int dayNumber;
  final String monthDayLabel;
}

List<_MedsDayData> _buildCurrentWeekDays(DateTime today) {
  final monday = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(Duration(days: today.weekday - 1));

  return List.generate(7, (index) {
    final date = monday.add(Duration(days: index));
    return _MedsDayData(
      date: date,
      weekday: index + 1,
      shortLabel: _weekdayShortLabel(date.weekday),
      fullLabel: _weekdayFullLabel(date.weekday),
      dayNumber: date.day,
      monthDayLabel: '${_monthLabel(date.month)} ${date.day}',
    );
  });
}

String _weekdayShortLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'M';
    case DateTime.tuesday:
      return 'T';
    case DateTime.wednesday:
      return 'W';
    case DateTime.thursday:
      return 'T';
    case DateTime.friday:
      return 'F';
    case DateTime.saturday:
      return 'S';
    case DateTime.sunday:
      return 'S';
  }
  return '';
}

String _weekdayFullLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Monday';
    case DateTime.tuesday:
      return 'Tuesday';
    case DateTime.wednesday:
      return 'Wednesday';
    case DateTime.thursday:
      return 'Thursday';
    case DateTime.friday:
      return 'Friday';
    case DateTime.saturday:
      return 'Saturday';
    case DateTime.sunday:
      return 'Sunday';
  }
  return '';
}

String _monthLabel(int month) {
  switch (month) {
    case 1:
      return 'January';
    case 2:
      return 'February';
    case 3:
      return 'March';
    case 4:
      return 'April';
    case 5:
      return 'May';
    case 6:
      return 'June';
    case 7:
      return 'July';
    case 8:
      return 'August';
    case 9:
      return 'September';
    case 10:
      return 'October';
    case 11:
      return 'November';
    case 12:
      return 'December';
  }
  return '';
}
