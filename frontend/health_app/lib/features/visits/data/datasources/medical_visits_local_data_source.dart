import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
      return const [];
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
            json['doctorName'] = 'Р”-СЂ РЎР°СЂР° РњРёС‚С‡РµР»Р»';
          }
          if (json['specialty'] == 'Cardiologist') {
            json['specialty'] = 'РљР°СЂРґРёРѕР»РѕРі';
          }
          if (json['location'] == 'Heart Care Center, Floor 3') {
            json['location'] = 'РљР°СЂРґРёРѕС†РµРЅС‚СЂ, СЌС‚Р°Р¶ 3';
          }
          break;
        case 'visit-002':
          if (json['doctorName'] == 'Dr. Aisha Patel') {
            json['doctorName'] = 'Р”-СЂ РђР№С€Р° РџР°С‚РµР»';
          }
          if (json['specialty'] == 'Endocrinologist') {
            json['specialty'] = 'Р­РЅРґРѕРєСЂРёРЅРѕР»РѕРі';
          }
          if (json['location'] == 'Diabetes & Hormones Clinic') {
            json['location'] = 'РљР»РёРЅРёРєР° РґРёР°Р±РµС‚Р° Рё РіРѕСЂРјРѕРЅРѕРІ';
          }
          break;
      }
      return json;
    }).toList();
  }
}
