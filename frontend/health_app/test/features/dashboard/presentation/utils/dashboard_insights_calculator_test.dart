import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/dashboard/domain/entities/blood_pressure_reading.dart';
import 'package:health_app/features/dashboard/presentation/utils/dashboard_insights_calculator.dart';
import 'package:health_app/features/profile/domain/entities/user_profile.dart';

void main() {
  test('calculates blood pressure and body mass insights from local data', () {
    final now = DateTime.now();
    final profile = UserProfile(
      id: 'profile',
      fullName: 'Иван Петров',
      email: 'ivan@example.com',
      phone: '',
      gender: ProfileGender.male,
      birthDate: DateTime(now.year - 30, now.month, now.day),
      age: null,
      bloodType: 'A+',
      heightCm: 180,
      weightKg: 92,
      primaryDoctor: null,
      emergencyContactName: null,
      emergencyContactDetails: null,
      notificationsEnabled: true,
      createdAt: now,
      updatedAt: now,
    );
    final readings = [
      BloodPressureReading(
        id: '1',
        systolic: 138,
        diastolic: 86,
        pulse: 78,
        recordedAt: now.subtract(const Duration(days: 1)),
        createdAt: now,
        updatedAt: now,
      ),
      BloodPressureReading(
        id: '2',
        systolic: 136,
        diastolic: 84,
        pulse: 76,
        recordedAt: now.subtract(const Duration(days: 2)),
        createdAt: now,
        updatedAt: now,
      ),
      BloodPressureReading(
        id: '3',
        systolic: 126,
        diastolic: 80,
        pulse: 74,
        recordedAt: now.subtract(const Duration(days: 10)),
        createdAt: now,
        updatedAt: now,
      ),
      BloodPressureReading(
        id: '4',
        systolic: 124,
        diastolic: 78,
        pulse: 73,
        recordedAt: now.subtract(const Duration(days: 12)),
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final result = DashboardInsightsCalculator.fromLocalData(
      profile: profile,
      readings: readings,
    );

    expect(result.bloodPressure.hasReadings, isTrue);
    expect(result.bloodPressure.latestCategory, 'highStage1');
    expect(result.bodyMass.hasBodyMassData, isTrue);
    expect(result.bodyMass.bmi, closeTo(28.4, 0.1));
    expect(result.bodyMass.category, 'overweight');
    expect(result.riskSignals, isNotEmpty);
    expect(
      result.riskSignals.map((item) => item.key),
      containsAll(['bloodPressureAttention', 'overweightRisk']),
    );
  });

  test('uses pediatric blood pressure mode for children under 13', () {
    final now = DateTime.now();
    final profile = UserProfile(
      id: 'profile-child',
      fullName: 'Анна Иванова',
      email: 'anna@example.com',
      phone: '',
      gender: ProfileGender.female,
      birthDate: DateTime(now.year - 10, now.month, now.day),
      age: null,
      bloodType: null,
      heightCm: 145,
      weightKg: 38,
      primaryDoctor: null,
      emergencyContactName: null,
      emergencyContactDetails: null,
      notificationsEnabled: true,
      createdAt: now,
      updatedAt: now,
    );
    final readings = [
      BloodPressureReading(
        id: '1',
        systolic: 118,
        diastolic: 76,
        pulse: 82,
        recordedAt: now.subtract(const Duration(days: 1)),
        createdAt: now,
        updatedAt: now,
      ),
      BloodPressureReading(
        id: '2',
        systolic: 116,
        diastolic: 74,
        pulse: 80,
        recordedAt: now.subtract(const Duration(days: 3)),
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final result = DashboardInsightsCalculator.fromLocalData(
      profile: profile,
      readings: readings,
    );

    expect(result.bloodPressure.latestCategory, 'requiresPediatricAssessment');
    expect(result.bloodPressure.normalRangePercent, isNull);
  });
}
