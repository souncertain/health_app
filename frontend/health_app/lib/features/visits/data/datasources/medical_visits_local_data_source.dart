import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/medical_visit.dart';
import '../models/medical_visit_model.dart';

class MedicalVisitsLocalDataSource {
  MedicalVisitsLocalDataSource();

  static const _storageKey = 'visits.medical_visits';
  static const _storageVersionKey = 'visits.medical_visits.version';
  static const _currentStorageVersion = 2;

  Future<List<MedicalVisitModel>> getVisits() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      final seeded = _buildSeedVisits();
      await saveAll(seeded);
      return seeded;
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final storedVersion = preferences.getInt(_storageVersionKey) ?? 1;
    final normalizedDecoded = storedVersion < _currentStorageVersion
        ? _migrateStoredVisits(decoded)
        : decoded
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();

    final visits = normalizedDecoded.map(MedicalVisitModel.fromJson).toList();

    if (storedVersion < _currentStorageVersion) {
      await saveAll(visits);
    }

    return visits;
  }

  Future<void> saveAll(List<MedicalVisitModel> visits) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(visits.map((item) => item.toJson()).toList());
    await preferences.setString(_storageKey, encoded);
    await preferences.setInt(_storageVersionKey, _currentStorageVersion);
  }

  List<Map<String, dynamic>> _migrateStoredVisits(List<dynamic> decoded) {
    return decoded.map((item) {
      final json = Map<String, dynamic>.from(item as Map);
      final id = json['id'] as String? ?? '';
      switch (id) {
        case 'visit-001':
          if (json['doctorName'] == 'Dr. Sarah Mitchell') {
            json['doctorName'] = 'Д-р Сара Митчелл';
          }
          if (json['specialty'] == 'Cardiologist') {
            json['specialty'] = 'Кардиолог';
          }
          if (json['location'] == 'Heart Care Center, Floor 3') {
            json['location'] = 'Кардиоцентр, этаж 3';
          }
          break;
        case 'visit-002':
          if (json['doctorName'] == 'Dr. Aisha Patel') {
            json['doctorName'] = 'Д-р Айша Пател';
          }
          if (json['specialty'] == 'Endocrinologist') {
            json['specialty'] = 'Эндокринолог';
          }
          if (json['location'] == 'Diabetes & Hormones Clinic') {
            json['location'] = 'Клиника диабета и гормонов';
          }
          break;
      }
      return json;
    }).toList();
  }

  List<MedicalVisitModel> _buildSeedVisits() {
    final today = MedicalVisit.normalizeDate(DateTime.now());

    return [
      MedicalVisitModel(
        id: 'visit-001',
        doctorName: 'Д-р Сара Митчелл',
        specialty: 'Кардиолог',
        appointmentDate: today.add(const Duration(days: 4)),
        timeInMinutes: 10 * 60 + 30,
        location: 'Кардиоцентр, этаж 3',
        visitType: MedicalVisitType.oneTime,
        rating: 4.9,
        createdAt: today.subtract(const Duration(days: 20)),
        updatedAt: today,
      ),
      MedicalVisitModel(
        id: 'visit-002',
        doctorName: 'Д-р Айша Пател',
        specialty: 'Эндокринолог',
        appointmentDate: today.add(const Duration(days: 9)),
        timeInMinutes: 14 * 60,
        location: 'Клиника диабета и гормонов',
        visitType: MedicalVisitType.recurring,
        rating: 4.8,
        createdAt: today.subtract(const Duration(days: 14)),
        updatedAt: today,
      ),
    ];
  }
}
