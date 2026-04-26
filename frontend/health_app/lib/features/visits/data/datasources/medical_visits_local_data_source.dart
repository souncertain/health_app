import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/medical_visit.dart';
import '../models/medical_visit_model.dart';

class MedicalVisitsLocalDataSource {
  MedicalVisitsLocalDataSource();

  static const _storageKey = 'visits.medical_visits';

  Future<List<MedicalVisitModel>> getVisits() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      final seeded = _buildSeedVisits();
      await saveAll(seeded);
      return seeded;
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => MedicalVisitModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<MedicalVisitModel> visits) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(visits.map((item) => item.toJson()).toList());
    await preferences.setString(_storageKey, encoded);
  }

  List<MedicalVisitModel> _buildSeedVisits() {
    final today = MedicalVisit.normalizeDate(DateTime.now());

    return [
      MedicalVisitModel(
        id: 'visit-001',
        doctorName: 'Dr. Sarah Mitchell',
        specialty: 'Cardiologist',
        appointmentDate: today.add(const Duration(days: 4)),
        timeInMinutes: 10 * 60 + 30,
        location: 'Heart Care Center, Floor 3',
        visitType: MedicalVisitType.oneTime,
        rating: 4.9,
        createdAt: today.subtract(const Duration(days: 20)),
        updatedAt: today,
      ),
      MedicalVisitModel(
        id: 'visit-002',
        doctorName: 'Dr. Aisha Patel',
        specialty: 'Endocrinologist',
        appointmentDate: today.add(const Duration(days: 9)),
        timeInMinutes: 14 * 60,
        location: 'Diabetes & Hormones Clinic',
        visitType: MedicalVisitType.recurring,
        rating: 4.8,
        createdAt: today.subtract(const Duration(days: 14)),
        updatedAt: today,
      ),
    ];
  }
}
