import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'codecs.dart';

/// The only thing the store needs from the platform. Swappable for a real
/// database later (ADR-009) and for memory in tests.
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// On-device storage: SharedPreferences on Android/iOS, localStorage on web.
final class PrefsStore implements KeyValueStore {
  PrefsStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);
}

/// In-memory store for tests and previews.
class MemoryStore implements KeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// Data found on the device at startup. Null sections mean "nothing saved
/// yet" (or unreadable — see [AppStore.load]).
final class SavedData {
  const SavedData({this.fridge, this.budget, this.barcodes, this.profile});

  final SavedFridge? fridge;
  final SavedBudget? budget;
  final SavedBarcodes? barcodes;
  final SavedProfile? profile;

  /// Nothing of the user's on the device yet: a brand-new install.
  bool get isFreshInstall => fridge == null && budget == null;
}

/// Loads saved sections once at startup and writes them back on change,
/// coalescing bursts of changes into one write per section.
final class AppStore {
  AppStore(this._kv, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const fridgeKey = 'recipix.fridge.v1';
  static const budgetKey = 'recipix.budget.v1';
  static const barcodesKey = 'recipix.barcodes.v1';
  static const profileKey = 'recipix.profile.v1';

  final KeyValueStore _kv;
  final DateTime Function() _clock;
  final Map<String, String> _pending = {};
  Future<void>? _flushing;

  Future<SavedData> load() async => SavedData(
    fridge: await _section(fridgeKey, SavedFridge.fromJson),
    budget: await _section(budgetKey, SavedBudget.fromJson),
    barcodes: await _section(barcodesKey, SavedBarcodes.fromJson),
    profile: await _section(profileKey, SavedProfile.fromJson),
  );

  /// Unreadable data is never silently overwritten: the raw text is copied
  /// to `<key>.corrupt.<timestamp>` first, then the app starts fresh.
  Future<T?> _section<T>(
    String key,
    T Function(Map<String, Object?>) decode,
  ) async {
    final raw = await _kv.read(key);
    if (raw == null) return null;
    try {
      return decode(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      await _kv.write('$key.corrupt.${_clock().millisecondsSinceEpoch}', raw);
      return null;
    }
  }

  void saveFridge(SavedFridge data) => _queue(fridgeKey, data.toJson());

  void saveBudget(SavedBudget data) => _queue(budgetKey, data.toJson());

  void saveBarcodes(SavedBarcodes data) => _queue(barcodesKey, data.toJson());

  void saveProfile(SavedProfile data) => _queue(profileKey, data.toJson());

  void _queue(String key, Map<String, Object?> json) {
    _pending[key] = jsonEncode(json);
    _flushing ??= Future.microtask(_write);
  }

  Future<void> _write() async {
    try {
      while (_pending.isNotEmpty) {
        final batch = Map.of(_pending);
        _pending.clear();
        for (final e in batch.entries) {
          await _kv.write(e.key, e.value);
        }
      }
    } finally {
      _flushing = null;
    }
  }

  /// Completes when queued writes are on disk. For tests and app pause.
  Future<void> flush() async {
    while (_flushing != null) {
      await _flushing;
    }
  }
}

/// Null when the app runs without storage (most tests).
final appStoreProvider = Provider<AppStore?>((ref) => null);

/// What was on the device at startup; injected from `main()`.
final savedDataProvider = Provider<SavedData>((ref) => const SavedData());
