extension IterableFirstWhereOrNullExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) {
        return item;
      }
    }

    return null;
  }
}

extension ListUpsertExtension<T> on List<T> {
  void upsertWhere(T value, bool Function(T item) test) {
    final index = indexWhere(test);
    if (index == -1) {
      add(value);
      return;
    }

    this[index] = value;
  }
}
