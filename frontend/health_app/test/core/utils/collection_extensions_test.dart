import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/core/utils/collection_extensions.dart';

void main() {
  group('IterableFirstWhereOrNullExtension', () {
    test('returns first matching item', () {
      final result = [1, 2, 3, 4].firstWhereOrNull((item) => item.isEven);

      expect(result, 2);
    });

    test('returns null when nothing matches', () {
      final result = [1, 3, 5].firstWhereOrNull((item) => item.isEven);

      expect(result, isNull);
    });
  });

  group('ListUpsertExtension', () {
    test('adds value when nothing matches', () {
      final values = <int>[1, 2];

      values.upsertWhere(3, (item) => item == 3);

      expect(values, [1, 2, 3]);
    });

    test('replaces first matching value when item exists', () {
      final values = <int>[1, 2, 3];

      values.upsertWhere(20, (item) => item == 2);

      expect(values, [1, 20, 3]);
    });
  });
}
