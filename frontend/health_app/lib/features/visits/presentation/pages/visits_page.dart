import 'package:flutter/material.dart';

import '../../../../core/layout/app_layout_constants.dart';
import '../../../../core/utils/date_time_labels.dart';
import '../../data/datasources/medical_visits_local_data_source.dart';
import '../../data/datasources/medical_visits_remote_data_source.dart';
import '../../data/repositories/backend_medical_visit_repository.dart';
import '../../domain/entities/medical_visit.dart';
import '../../domain/repositories/medical_visit_repository.dart';
import '../../domain/usecases/delete_medical_visit.dart';
import '../../domain/usecases/get_cached_medical_visits.dart';
import '../../domain/usecases/get_medical_visits.dart';
import '../../domain/usecases/save_medical_visit.dart';
import '../controllers/visits_controller.dart';
import '../widgets/appointment_sheet.dart';

class VisitsPage extends StatefulWidget {
  const VisitsPage({super.key, this.repository});

  final MedicalVisitRepository? repository;

  @override
  State<VisitsPage> createState() => VisitsPageState();
}

class VisitsPageState extends State<VisitsPage> {
  late final VisitsController _controller;
  MedicalVisitType _selectedFilter = MedicalVisitType.oneTime;

  @override
  void initState() {
    super.initState();
    final repository =
        widget.repository ??
        BackendMedicalVisitRepository(
          localDataSource: MedicalVisitsLocalDataSource(),
          remoteDataSource: MedicalVisitsRemoteDataSource(),
        );
    _controller = VisitsController(
      getCachedVisits: GetCachedMedicalVisitsUseCase(repository),
      getVisits: GetMedicalVisitsUseCase(repository),
      saveVisit: SaveMedicalVisitUseCase(repository),
      deleteVisit: DeleteMedicalVisitUseCase(repository),
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> openCreateAppointmentSheet() {
    return showAppointmentSheet(
      context: context,
      onSubmit: (value) {
        return _controller.saveVisit(
          doctorName: value.doctorName,
          specialty: value.specialty,
          appointmentDate: value.appointmentDate,
          timeInMinutes: value.timeInMinutes,
          location: value.location,
          visitType: value.visitType,
        );
      },
    );
  }

  Future<void> _openEditAppointmentSheet(MedicalVisit visit) {
    return showAppointmentSheet(
      context: context,
      initialVisit: visit,
      onSubmit: (value) {
        return _controller.saveVisit(
          existingVisit: visit,
          doctorName: value.doctorName,
          specialty: value.specialty,
          appointmentDate: value.appointmentDate,
          timeInMinutes: value.timeInMinutes,
          location: value.location,
          visitType: value.visitType,
        );
      },
    );
  }

  Future<void> _handleReschedule(MedicalVisit visit) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: visit.timeInMinutes ~/ 60,
        minute: visit.timeInMinutes % 60,
      ),
    );

    if (selected == null) {
      return;
    }

    try {
      await _controller.rescheduleVisit(
        visit,
        selected.hour * 60 + selected.minute,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось перенести визит.')),
      );
    }
  }

  Future<void> _handleDelete(MedicalVisit visit) async {
    try {
      await _controller.deleteVisit(visit);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось отменить визит.')),
      );
    }
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
            final visits = _controller.visitsForType(_selectedFilter);
            final nextVisit = _controller.nextVisitForType(_selectedFilter);

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _VisitsHeader(
                            isCompact: isCompact,
                            selectedFilter: _selectedFilter,
                            nextVisit: nextVisit,
                            remainingLabel: nextVisit == null
                                ? null
                                : _buildRemainingLabel(nextVisit),
                            nextVisitSubtitle: nextVisit == null
                                ? 'Добавьте первую запись к врачу'
                                : '${nextVisit.doctorName} - ${formatShortMonthDate(nextVisit.appointmentDate)}',
                            onFilterSelected: (filter) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            onAddTap: openCreateAppointmentSheet,
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              24,
                              horizontalPadding,
                              0,
                            ),
                            child: visits.isEmpty
                                ? _EmptyVisitsState(
                                    visitType: _selectedFilter,
                                    onAddPressed: openCreateAppointmentSheet,
                                  )
                                : Column(
                                    children: visits
                                        .map(
                                          (visit) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 20,
                                            ),
                                            child: _VisitCard(
                                              visit: visit,
                                              compact: isCompact,
                                              dateText: _formatLongDate(
                                                visit.appointmentDate,
                                              ),
                                              timeText: formatMinutesAsClock(
                                                visit.timeInMinutes,
                                              ),
                                              onTap: () =>
                                                  _openEditAppointmentSheet(
                                                    visit,
                                                  ),
                                              onReschedule: () =>
                                                  _handleReschedule(visit),
                                              onCancel: () =>
                                                  _handleDelete(visit),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ),

                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              18,
                              horizontalPadding,
                              kPageBottomOverlayPadding,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: openCreateAppointmentSheet,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF9200),
                                  foregroundColor: Colors.white,
                                  elevation: 10,
                                  shadowColor: const Color(
                                    0xFFEF9200,
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
                                  'Записаться',
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
                if (_controller.isLoading && _controller.visits.isEmpty)
                  const Center(child: CircularProgressIndicator()),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatLongDate(DateTime date) {
    return formatLongMonthDate(date);
  }

  String _buildRemainingLabel(MedicalVisit visit) {
    final today = MedicalVisit.normalizeDate(DateTime.now());
    final difference = visit.appointmentDate.difference(today).inDays;

    if (difference <= 0) {
      return 'Сегодня';
    }
    if (difference == 1) {
      return '1 день';
    }
    return '$difference дн.';
  }
}

class _VisitsHeader extends StatelessWidget {
  const _VisitsHeader({
    required this.isCompact,
    required this.selectedFilter,
    required this.nextVisit,
    required this.remainingLabel,
    required this.nextVisitSubtitle,
    required this.onFilterSelected,
    required this.onAddTap,
  });

  final bool isCompact;
  final MedicalVisitType selectedFilter;
  final MedicalVisit? nextVisit;
  final String? remainingLabel;
  final String nextVisitSubtitle;
  final ValueChanged<MedicalVisitType> onFilterSelected;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFFEF9200)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 16 : 20,
          24,
          isCompact ? 16 : 20,
          30,
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
                        'Приемы',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: isCompact ? 15 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Визиты к врачу',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 28 : 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onAddTap,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ближайший визит',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          nextVisitSubtitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        remainingLabel ?? 'Визитов нет',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextVisit == null ? 'запланировано' : 'осталось',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _VisitFilterChip(
                    label: 'Разовый',
                    icon: Icons.calendar_today_rounded,
                    selected: selectedFilter == MedicalVisitType.oneTime,
                    onTap: () => onFilterSelected(MedicalVisitType.oneTime),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VisitFilterChip(
                    label: 'Регулярный',
                    icon: Icons.sync_rounded,
                    selected: selectedFilter == MedicalVisitType.recurring,
                    onTap: () => onFilterSelected(MedicalVisitType.recurring),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitFilterChip extends StatelessWidget {
  const _VisitFilterChip({
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? const Color(0xFFEF9200) : Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFFEF9200) : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyVisitsState extends StatelessWidget {
  const _EmptyVisitsState({
    required this.visitType,
    required this.onAddPressed,
  });

  final MedicalVisitType visitType;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD5EFD9).withValues(alpha: 0.26),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_rounded,
            color: Color(0xFFEF9200),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            visitType == MedicalVisitType.oneTime
                ? 'Разовых визитов пока нет'
                : 'Регулярных визитов пока нет',
            style: const TextStyle(
              color: Color(0xFF12203F),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Добавьте визит к врачу, чтобы отслеживать предстоящие посещения.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF61738F),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAddPressed,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF9200),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Записаться',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitCardPalette {
  const _VisitCardPalette({
    required this.accentBackground,
    required this.specialtyColor,
    required this.rescheduleBackground,
    required this.rescheduleForeground,
  });

  final Color accentBackground;
  final Color specialtyColor;
  final Color rescheduleBackground;
  final Color rescheduleForeground;

  factory _VisitCardPalette.fromType(MedicalVisitType type) {
    switch (type) {
      case MedicalVisitType.oneTime:
        return const _VisitCardPalette(
          accentBackground: Color(0xFFFFE1E1),
          specialtyColor: Color(0xFFEF2D2D),
          rescheduleBackground: Color(0xFFFCE0E0),
          rescheduleForeground: Color(0xFFEF2D2D),
        );
      case MedicalVisitType.recurring:
        return const _VisitCardPalette(
          accentBackground: Color(0xFFEDE8FF),
          specialtyColor: Color(0xFF7C3AED),
          rescheduleBackground: Color(0xFFEEE8FF),
          rescheduleForeground: Color(0xFF7C3AED),
        );
    }
  }
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.visit,
    required this.compact,
    required this.dateText,
    required this.timeText,
    required this.onTap,
    required this.onReschedule,
    required this.onCancel,
  });

  final MedicalVisit visit;
  final bool compact;
  final String dateText;
  final String timeText;
  final VoidCallback onTap;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final palette = _VisitCardPalette.fromType(visit.visitType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 18 : 22,
            compact ? 20 : 24,
            compact ? 18 : 22,
            compact ? 18 : 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD5EFD9).withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: palette.accentBackground,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.medical_information_rounded,
                      color: Color(0xFF6F86A9),
                      size: 38,
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
                                visit.doctorName,
                                style: TextStyle(
                                  color: const Color(0xFF0C1C46),
                                  fontSize: compact ? 18 : 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF5A623),
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  visit.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Color(0xFF6F86A9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          visit.specialty,
                          style: TextStyle(
                            color: palette.specialtyColor,
                            fontSize: compact ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _VisitDetailRow(
                          icon: Icons.calendar_month_rounded,
                          text: dateText,
                        ),
                        const SizedBox(height: 8),
                        _VisitDetailRow(
                          icon: Icons.access_time_rounded,
                          text: timeText,
                        ),
                        const SizedBox(height: 8),
                        _VisitDetailRow(
                          icon: Icons.location_on_outlined,
                          text: visit.location,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _VisitActionButton(
                      label: 'Перенести',
                      background: palette.rescheduleBackground,
                      foreground: palette.rescheduleForeground,
                      onTap: onReschedule,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _VisitActionButton(
                      label: 'Отменить',
                      background: const Color(0xFFFCE0E0),
                      foreground: const Color(0xFFEF2D2D),
                      onTap: onCancel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 58,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5FB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF8DA2C0),
                      size: 28,
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
}

class _VisitDetailRow extends StatelessWidget {
  const _VisitDetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF94A8C7)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF5B7397),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _VisitActionButton extends StatelessWidget {
  const _VisitActionButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
