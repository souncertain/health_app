import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/meds/presentation/pages/meds_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';
import '../../../../support/widget_test_helpers.dart';

void main() {
  late MockMedicationRepository repository;

  setUp(() {
    repository = MockMedicationRepository();
  });

  testWidgets('renders empty state when there are no medications', (tester) async {
    when(
      () => repository.getCachedMedications(),
    ).thenAnswer((_) async => const []);
    when(() => repository.getMedications()).thenAnswer((_) async => const []);

    await pumpTestApp(tester, MedsPage(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Препараты еще не добавлены'), findsOneWidget);
    expect(find.text('Добавить препарат'), findsAtLeastNWidgets(1));
  });

  testWidgets('renders medication card from repository data', (tester) async {
    final medication = sampleMedication(
      name: 'Аспирин',
      dosage: '10 мг',
      createdAt: DateTime(2026, 5, 1),
    );
    when(
      () => repository.getCachedMedications(),
    ).thenAnswer((_) async => [medication]);
    when(() => repository.getMedications()).thenAnswer((_) async => [medication]);

    await pumpTestApp(tester, MedsPage(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Аспирин'), findsAtLeastNWidgets(1));
    expect(find.textContaining('10 мг'), findsAtLeastNWidgets(1));
  });
}
