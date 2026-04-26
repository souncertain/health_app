import 'package:flutter/material.dart';

import '../../domain/entities/blood_pressure_reading.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/blood_pressure_reading_sheet.dart';
import '../widgets/dashboard_reading_card.dart';

class AllReadingsPage extends StatelessWidget {
  const AllReadingsPage({super.key, required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FFF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Все измерения',
          style: TextStyle(
            color: Color(0xFF0C1C46),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.isLoading && controller.allReadings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.allReadings.isEmpty) {
            return const Center(
              child: Text(
                'Измерений пока нет',
                style: TextStyle(
                  color: Color(0xFF90A4C4),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            itemCount: controller.allReadings.length,
            separatorBuilder: (context, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final reading = controller.allReadings[index];
              return DashboardReadingCard(
                reading: reading,
                detailed: true,
                onTap: () => _openEditSheet(context, reading),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditSheet(
    BuildContext context,
    BloodPressureReading reading,
  ) {
    return showBloodPressureReadingSheet(
      context: context,
      initialReading: reading,
      onSubmit: (value) {
        return controller.saveReading(
          existingReading: reading,
          systolic: value.systolic,
          diastolic: value.diastolic,
          pulse: value.pulse,
        );
      },
      onDelete: () => controller.deleteReading(reading),
    );
  }
}
