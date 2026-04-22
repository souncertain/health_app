import 'package:flutter/material.dart';

import '../../domain/entities/medical_visit.dart';

enum VisitFilter { oneTime, recurring }

class VisitsPage extends StatefulWidget {
  const VisitsPage({super.key});

  @override
  State<VisitsPage> createState() => _VisitsPageState();
}

class _VisitsPageState extends State<VisitsPage> {
  VisitFilter _selectedFilter = VisitFilter.oneTime;

  static const List<MedicalVisit> _visits = [
    MedicalVisit(
      doctorName: 'Dr. Sarah Mitchell',
      specialty: 'Cardiologist',
      date: 'April 20, 2026',
      time: '10:30 AM',
      location: 'Heart Care Center, Floor 3',
      rating: 4.9,
      accentColorHex: 0xFFFFE1E1,
    ),
    MedicalVisit(
      doctorName: 'Dr. Aisha Patel',
      specialty: 'Endocrinologist',
      date: 'May 5, 2026',
      time: '02:00 PM',
      location: 'Diabetes & Hormones Clinic',
      rating: 4.8,
      accentColorHex: 0xFFEDE8FF,
    ),
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
                  _VisitsHeader(
                    isCompact: isCompact,
                    selectedFilter: _selectedFilter,
                    onFilterSelected: (filter) {
                      setState(() {
                        _selectedFilter = filter;
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
                      children: _visits
                          .map(
                            (visit) => Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _VisitCard(
                                visit: visit,
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
                      4,
                      horizontalPadding,
                      0,
                    ),
                    child: const _PrescriptionScannerCard(),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      18,
                      horizontalPadding,
                      148,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
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
                          'Book Appointment',
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

class _VisitsHeader extends StatelessWidget {
  const _VisitsHeader({
    required this.isCompact,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final bool isCompact;
  final VisitFilter selectedFilter;
  final ValueChanged<VisitFilter> onFilterSelected;

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
                        'Appointments',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: isCompact ? 15 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Medical Visits',
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
                    Icons.medical_services_rounded,
                    color: Colors.white,
                    size: 28,
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Appointment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Dr. Sarah Mitchell · April 20',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '4 days',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'remaining',
                        style: TextStyle(
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
                    label: 'One-Time',
                    icon: Icons.calendar_today_rounded,
                    selected: selectedFilter == VisitFilter.oneTime,
                    onTap: () => onFilterSelected(VisitFilter.oneTime),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VisitFilterChip(
                    label: 'Recurring',
                    icon: Icons.sync_rounded,
                    selected: selectedFilter == VisitFilter.recurring,
                    onTap: () => onFilterSelected(VisitFilter.recurring),
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

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit, required this.compact});

  final MedicalVisit visit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(visit.accentColorHex);

    return Container(
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
                  color: accentColor,
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
                        color: accentColor == const Color(0xFFEDE8FF)
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFFEF2D2D),
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _VisitDetailRow(
                      icon: Icons.calendar_month_rounded,
                      text: visit.date,
                    ),
                    const SizedBox(height: 8),
                    _VisitDetailRow(
                      icon: Icons.access_time_rounded,
                      text: visit.time,
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
                  label: 'Reschedule',
                  foreground: accentColor == const Color(0xFFEDE8FF)
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFFEF2D2D),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: _VisitActionButton(
                  label: 'Cancel',
                  foreground: Color(0xFFEF2D2D),
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
  const _VisitActionButton({required this.label, required this.foreground});

  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE0E0),
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
    );
  }
}

class _PrescriptionScannerCard extends StatelessWidget {
  const _PrescriptionScannerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF67E5A2),
          style: BorderStyle.solid,
        ),
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
                      'AI Prescription Scanner',
                      style: TextStyle(
                        color: Color(0xFF0C1C46),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Upload a prescription to extract medications',
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
              onPressed: () {},
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
                'Scan Prescription',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
