import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/core/controllers/cache_first_collection_controller.dart';

class TestCacheFirstController extends CacheFirstCollectionController<int> {
  List<int> cachedItems = const [];
  List<int> remoteItems = const [];
  Object? cachedError;
  Object? remoteError;
  final List<List<int>> updatedSnapshots = [];
  int cachedLoadCount = 0;
  int remoteLoadCount = 0;

  List<int> get items => List.unmodifiable(currentItems);

  @override
  String get refreshErrorMessage => 'refresh failed';

  @override
  Future<List<int>> loadCachedItems() async {
    cachedLoadCount++;
    if (cachedError != null) {
      throw cachedError!;
    }
    return cachedItems;
  }

  @override
  Future<List<int>> loadRemoteItems() async {
    remoteLoadCount++;
    if (remoteError != null) {
      throw remoteError!;
    }
    return remoteItems;
  }

  @override
  List<int> sortItems(List<int> items) => List<int>.from(items)..sort();

  @override
  Future<void> onItemsUpdated(List<int> items) async {
    updatedSnapshots.add(List<int>.from(items));
  }

  Future<void> optimisticMutation({
    required List<int> nextItems,
    required Future<void> Function() action,
    required String errorMessage,
    bool rethrowOnFailure = false,
  }) {
    return runOptimisticMutation(
      nextItems: nextItems,
      action: action,
      errorMessage: errorMessage,
      rethrowOnFailure: rethrowOnFailure,
    );
  }
}

Future<void> flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('initialize loads cached items and eventually refreshes remote items', () async {
    final controller = TestCacheFirstController()
      ..cachedItems = [3, 1]
      ..remoteItems = [5, 4, 2];

    await controller.initialize();
    await flushMicrotasks();

    expect(controller.isInitialized, isTrue);
    expect(controller.items, [2, 4, 5]);
    expect(controller.cachedLoadCount, 1);
    expect(controller.remoteLoadCount, 1);
  });

  test('initialize only runs once', () async {
    final controller = TestCacheFirstController()
      ..cachedItems = [1]
      ..remoteItems = [2];

    await controller.initialize();
    await flushMicrotasks();
    await controller.initialize();

    expect(controller.cachedLoadCount, 1);
  });

  test('refresh stores error message when remote load fails', () async {
    final controller = TestCacheFirstController()..remoteError = Exception('boom');

    await controller.refresh();

    expect(controller.errorMessage, 'refresh failed');
    expect(controller.isLoading, isFalse);
  });

  test('loadCachedState keeps empty state when cache fails', () async {
    final controller = TestCacheFirstController()..cachedError = Exception('cache failed');

    await controller.initialize();

    expect(controller.items, isEmpty);
    expect(controller.cachedLoadCount, 1);
  });

  test('runOptimisticMutation persists final cache-backed state on success', () async {
    final controller = TestCacheFirstController()
      ..cachedItems = [1]
      ..remoteItems = [1];

    await controller.initialize();
    await flushMicrotasks();

    controller.cachedItems = [7, 8];
    await controller.optimisticMutation(
      nextItems: [8, 7],
      action: () async {},
      errorMessage: 'failure',
    );

    expect(controller.items, [7, 8]);
    expect(controller.errorMessage, isNull);
    expect(controller.isSaving, isFalse);
  });

  test('runOptimisticMutation reverts and stores error on failure', () async {
    final controller = TestCacheFirstController()
      ..cachedItems = [1]
      ..remoteItems = [1];

    await controller.initialize();
    await flushMicrotasks();

    await controller.optimisticMutation(
      nextItems: [9],
      action: () async => throw Exception('boom'),
      errorMessage: 'save failed',
    );

    expect(controller.items, [1]);
    expect(controller.errorMessage, 'save failed');
    expect(controller.isSaving, isFalse);
  });

  test('runOptimisticMutation rethrows when requested', () async {
    final controller = TestCacheFirstController();

    await expectLater(
      controller.optimisticMutation(
        nextItems: [1],
        action: () async => throw StateError('boom'),
        errorMessage: 'save failed',
        rethrowOnFailure: true,
      ),
      throwsStateError,
    );
  });
}
