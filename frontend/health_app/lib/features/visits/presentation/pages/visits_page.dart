import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/layout/app_layout_constants.dart';
import '../../../../core/ui/app_error_feedback.dart';
import '../../../../core/utils/date_time_labels.dart';
import '../../data/datasources/doctor_note_scanner_remote_data_source.dart';
import '../../data/datasources/medical_visits_local_data_source.dart';
import '../../data/datasources/medical_visits_remote_data_source.dart';
import '../../data/repositories/backend_medical_visit_repository.dart';
import '../../domain/entities/doctor_note_scan_result.dart';
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
  late final DoctorNoteScannerRemoteDataSource _scannerRemoteDataSource;
  MedicalVisitType _selectedFilter = MedicalVisitType.oneTime;
  final ImagePicker _imagePicker = ImagePicker();

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
    _scannerRemoteDataSource = DoctorNoteScannerRemoteDataSource();
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

  Future<void> _openDoctorNoteScanner() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Сканирование записи врача',
                style: TextStyle(
                  color: Color(0xFF12203F),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Выберите источник изображения, а затем приложение распознает текст и подскажет, относится ли запись к лекарствам или к визиту.',
                style: TextStyle(
                  color: Color(0xFF61738F),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              _ScannerSourceTile(
                icon: Icons.camera_alt_rounded,
                label: 'Сделать фото',
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              const SizedBox(height: 12),
              _ScannerSourceTile(
                icon: Icons.photo_library_rounded,
                label: 'Выбрать из галереи',
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) {
      return;
    }

    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 2200,
    );
    if (image == null || !mounted) {
      return;
    }

    await showDoctorNoteScanSheet(
      context,
      image: image,
      scannerRemoteDataSource: _scannerRemoteDataSource,
      onCreateVisit: _openAppointmentDraftFromScan,
    );
  }

  Future<void> _openAppointmentDraftFromScan(
    DoctorNoteVisitCandidate candidate,
  ) {
    return showAppointmentSheet(
      context: context,
      initialDraft: AppointmentFormDraft(
        doctorName: candidate.doctorName.isEmpty ? null : candidate.doctorName,
        specialty: candidate.specialty.isEmpty ? null : candidate.specialty,
        appointmentDate: _tryParseVisitDate(candidate.dateText),
        timeInMinutes: _tryParseTimeInMinutes(candidate.timeText),
        location: candidate.location.isEmpty ? null : candidate.location,
      ),
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

  DateTime? _tryParseVisitDate(String raw) {
    final match = RegExp(r'(\d{1,2})[./](\d{1,2})(?:[./](\d{2,4}))?').firstMatch(
      raw,
    );
    if (match == null) {
      return null;
    }

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    if (day == null || month == null) {
      return null;
    }

    final now = DateTime.now();
    final rawYear = match.group(3);
    var year = rawYear == null ? now.year : int.tryParse(rawYear);
    if (year == null) {
      return null;
    }
    if (year < 100) {
      year += 2000;
    }

    try {
      return MedicalVisit.normalizeDate(DateTime(year, month, day));
    } catch (_) {
      return null;
    }
  }

  int? _tryParseTimeInMinutes(String raw) {
    final match = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(raw);
    if (match == null) {
      return null;
    }

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return hour * 60 + minute;
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
                              visits.isEmpty ? 0 : 4,
                              horizontalPadding,
                              0,
                            ),
                            child: _PrescriptionScannerCard(
                              onTap: _openDoctorNoteScanner,
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

class _PrescriptionScannerCard extends StatelessWidget {
  const _PrescriptionScannerCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF67E5A2)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.center_focus_strong_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI-сканер рецепта',
                      style: TextStyle(
                        color: Color(0xFF0C1C46),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Загрузите рецепт, чтобы извлечь названия препаратов',
                      style: TextStyle(
                        color: Color(0xFF5B7397),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.upload_rounded, size: 24),
              label: const Text(
                'Сканировать рецепт',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerSourceTile extends StatelessWidget {
  const _ScannerSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7FBF8),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF1DB954)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF12203F),
                    fontSize: 16,
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
    );
  }
}

Future<void> showDoctorNoteScanSheet(
  BuildContext context, {
  required XFile image,
  required DoctorNoteScannerRemoteDataSource scannerRemoteDataSource,
  required Future<void> Function(DoctorNoteVisitCandidate candidate) onCreateVisit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => _DoctorNoteScanSheet(
      image: image,
      scannerRemoteDataSource: scannerRemoteDataSource,
      onCreateVisit: onCreateVisit,
    ),
  );
}

class _DoctorNoteScanSheet extends StatefulWidget {
  const _DoctorNoteScanSheet({
    required this.image,
    required this.scannerRemoteDataSource,
    required this.onCreateVisit,
  });

  final XFile image;
  final DoctorNoteScannerRemoteDataSource scannerRemoteDataSource;
  final Future<void> Function(DoctorNoteVisitCandidate candidate) onCreateVisit;

  @override
  State<_DoctorNoteScanSheet> createState() => _DoctorNoteScanSheetState();
}

class _DoctorNoteScanSheetState extends State<_DoctorNoteScanSheet> {
  DoctorNoteScanResult? _result;
  Object? _error;
  bool _isLoading = true;
  bool _isCreatingVisit = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.scannerRemoteDataSource.analyzeImage(
        widget.image,
      );
      if (!mounted) {
        return;
      }

      setState(() => _result = result);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createVisit(DoctorNoteVisitCandidate candidate) async {
    setState(() => _isCreatingVisit = true);
    try {
      Navigator.of(context).pop();
      await widget.onCreateVisit(candidate);
    } finally {
      if (mounted) {
        setState(() => _isCreatingVisit = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7E3F3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Результат AI-сканирования',
                style: TextStyle(
                  color: Color(0xFF12203F),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Проверьте распознанный текст и подтвердите данные перед сохранением. Не используйте результат без проверки.',
                style: TextStyle(
                  color: Color(0xFF61738F),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF1DB954)),
                  ),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Builder(
                    builder: (context) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          showAppErrorSnackBarForException(
                            context,
                            _error!,
                            fallbackMessage:
                                'Не удалось распознать запись врача.',
                          );
                        }
                      });
                      return const Text(
                        'Не удалось распознать запись врача. Попробуйте сделать более чёткое фото.',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      );
                    },
                  ),
                )
              else if (_result != null) ...[
                _ScanStatusCard(result: _result!),
                const SizedBox(height: 16),
                _ScanTextCard(
                  title: 'Краткий вывод',
                  value: _result!.summary.isEmpty
                      ? 'AI не смог сформулировать краткий вывод.'
                      : _result!.summary,
                ),
                const SizedBox(height: 16),
                if (_result!.warnings.isNotEmpty) ...[
                  _ScanWarningsCard(warnings: _result!.warnings),
                  const SizedBox(height: 16),
                ],
                if (_result!.visits.isNotEmpty) ...[
                  const Text(
                    'Найденные визиты',
                    style: TextStyle(
                      color: Color(0xFF12203F),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._result!.visits.map(
                    (visit) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ScannedVisitCard(
                        visit: visit,
                        busy: _isCreatingVisit,
                        onCreate: () => _createVisit(visit),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_result!.medications.isNotEmpty) ...[
                  const Text(
                    'Найденные препараты',
                    style: TextStyle(
                      color: Color(0xFF12203F),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._result!.medications.map(
                    (medication) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ScannedMedicationCard(medication: medication),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                _ScanTextCard(
                  title: 'Распознанный текст',
                  value: _result!.rawText.isEmpty
                      ? 'Текст не распознан.'
                      : _result!.rawText,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanStatusCard extends StatelessWidget {
  const _ScanStatusCard({required this.result});

  final DoctorNoteScanResult result;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (result.category) {
      DoctorNoteCategory.medication => ('Назначение препарата', const Color(0xFF1595C9)),
      DoctorNoteCategory.medicalVisit => ('Визит или направление', const Color(0xFFEF9200)),
      DoctorNoteCategory.mixed => ('Смешанная запись', const Color(0xFF7C3AED)),
      DoctorNoteCategory.unknown => ('Категория не определена', const Color(0xFF61738F)),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Определённая категория',
                  style: TextStyle(
                    color: Color(0xFF61738F),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanWarningsCard extends StatelessWidget {
  const _ScanWarningsCard({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF9D27B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Что стоит перепроверить',
            style: TextStyle(
              color: Color(0xFFB36B00),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final warning in warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: Color(0xFFB36B00),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning,
                      style: const TextStyle(
                        color: Color(0xFF845A13),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanTextCard extends StatelessWidget {
  const _ScanTextCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF12203F),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF475A77),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannedVisitCard extends StatelessWidget {
  const _ScannedVisitCard({
    required this.visit,
    required this.busy,
    required this.onCreate,
  });

  final DoctorNoteVisitCandidate visit;
  final bool busy;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            visit.doctorName.isEmpty ? 'Врач не распознан' : visit.doctorName,
            style: const TextStyle(
              color: Color(0xFF12203F),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (visit.specialty.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              visit.specialty,
              style: const TextStyle(
                color: Color(0xFFEF9200),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (visit.dateText.isNotEmpty) _CandidateInfoLine(label: 'Дата', value: visit.dateText),
          if (visit.timeText.isNotEmpty) _CandidateInfoLine(label: 'Время', value: visit.timeText),
          if (visit.location.isNotEmpty) _CandidateInfoLine(label: 'Место', value: visit.location),
          if (visit.note.isNotEmpty) _CandidateInfoLine(label: 'Примечание', value: visit.note),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : onCreate,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF9200),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Открыть как черновик визита',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannedMedicationCard extends StatelessWidget {
  const _ScannedMedicationCard({required this.medication});

  final DoctorNoteMedicationCandidate medication;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            medication.name.isEmpty
                ? 'Название препарата не распознано'
                : medication.name,
            style: const TextStyle(
              color: Color(0xFF12203F),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (medication.dosageText.isNotEmpty)
            _CandidateInfoLine(label: 'Дозировка', value: medication.dosageText),
          if (medication.frequencyText.isNotEmpty)
            _CandidateInfoLine(label: 'Частота', value: medication.frequencyText),
          if (medication.instructions.isNotEmpty)
            _CandidateInfoLine(label: 'Инструкция', value: medication.instructions),
          if (medication.note.isNotEmpty)
            _CandidateInfoLine(label: 'Примечание', value: medication.note),
        ],
      ),
    );
  }
}

class _CandidateInfoLine extends StatelessWidget {
  const _CandidateInfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xFF475A77),
            fontSize: 14,
            height: 1.45,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
