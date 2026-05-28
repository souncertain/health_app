import 'dart:async';

import 'package:flutter/foundation.dart';

abstract class CacheFirstCollectionController<T> extends ChangeNotifier {
  bool _isLoading = false;
  bool _isSaving = false;
  bool _initialized = false;
  String? _errorMessage;
  List<T> _items = const [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isInitialized => _initialized;
  String? get errorMessage => _errorMessage;

  @protected
  List<T> get currentItems => _items;

  @protected
  String get refreshErrorMessage;

  @protected
  Future<List<T>> loadCachedItems();

  @protected
  Future<List<T>> loadRemoteItems();

  @protected
  List<T> sortItems(List<T> items) => items;

  @protected
  Future<void> onItemsUpdated(List<T> items) async {}

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    await loadCachedState();
    unawaited(refresh(showLoading: _items.isEmpty));
  }

  Future<void> refresh({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      replaceItems(await loadRemoteItems());
      await onItemsUpdated(_items);
    } catch (_) {
      _errorMessage = refreshErrorMessage;
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  @protected
  Future<void> loadCachedState() async {
    try {
      replaceItems(await loadCachedItems());
      await onItemsUpdated(_items);
    } catch (_) {
      // Keep the current empty state if cached loading fails.
    }

    _isLoading = false;
    notifyListeners();
  }

  @protected
  Future<void> reloadFromCache() async {
    replaceItems(await loadCachedItems());
    await onItemsUpdated(_items);
  }

  @protected
  void replaceItems(List<T> items) {
    _items = sortItems(List<T>.from(items));
  }

  @protected
  Future<void> runOptimisticMutation({
    required List<T> nextItems,
    required Future<void> Function() action,
    required String errorMessage,
    bool rethrowOnFailure = false,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    final previousItems = List<T>.from(_items);
    replaceItems(nextItems);
    notifyListeners();

    try {
      await action();
      await reloadFromCache();
    } catch (_) {
      replaceItems(previousItems);
      _errorMessage = errorMessage;
      if (rethrowOnFailure) {
        rethrow;
      }
      notifyListeners();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
