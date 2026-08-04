import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/categories.dart';
import '../data/gallery_store.dart';
import '../models/gallery_entry.dart';

enum AppTab { roll, gallery }

/// One die's state.
class DieState {
  const DieState({
    required this.value,
    this.locked = false,
    this.spinning = false,
  });

  final String value;
  final bool locked;
  final bool spinning;

  DieState copyWith({String? value, bool? locked, bool? spinning}) {
    return DieState(
      value: value ?? this.value,
      locked: locked ?? this.locked,
      spinning: spinning ?? this.spinning,
    );
  }
}

/// Owns the dice, the gallery, and the selected tab.
///
/// Rolling is a chain of timers rather than a single animation: the value has
/// to actually change on each tick, and the interval widens as it settles
/// (70ms, then 85, 100, 115, 130, 145, 160 — seven ticks, ~805ms total).
class ArtspirationState extends ChangeNotifier {
  ArtspirationState({math.Random? random, GalleryStore? store})
      : _random = random ?? math.Random(),
        // Named parameters cannot be private, so this cannot be an
        // initializing formal.
        // ignore: prefer_initializing_formals
        _store = store {
    for (final category in DieCategory.values) {
      _dice[category] = DieState(value: category.roll(_random));
    }
  }

  final math.Random _random;
  final Map<DieCategory, DieState> _dice = {};
  final Map<DieCategory, Timer> _timers = {};
  final List<GalleryEntry> _gallery = [];

  /// Null means this session is in-memory only, which is what the tests and
  /// design previews want.
  final GalleryStore? _store;

  /// Writes run one at a time. Removing a card while its photo is still being
  /// written would otherwise race, and the loser would decide what's on disk.
  Future<void> _writes = Future.value();

  AppTab _tab = AppTab.roll;

  static const _tickCount = 7;
  static const _baseDelayMs = 70;
  static const _delayStepMs = 15;

  AppTab get tab => _tab;
  List<GalleryEntry> get gallery => List.unmodifiable(_gallery);

  /// Completes once queued writes have drained. Tests await this; the app does
  /// not need to.
  Future<void> get settled => _writes;
  DieState die(DieCategory category) => _dice[category]!;

  set tab(AppTab value) {
    if (_tab == value) return;
    _tab = value;
    notifyListeners();
  }

  void toggleLock(DieCategory category) {
    final current = _dice[category]!;
    _dice[category] = current.copyWith(locked: !current.locked);
    notifyListeners();
  }

  /// Spins one die. Locked dice ignore this, which is also what makes
  /// [rollAll] skip them.
  void spin(DieCategory category) {
    if (_dice[category]!.locked) return;

    _timers[category]?.cancel();
    _dice[category] = _dice[category]!.copyWith(spinning: true);
    notifyListeners();

    var tick = 0;
    void flick() {
      tick++;
      final current = _dice[category]!;
      _dice[category] = current.copyWith(
        value: category.roll(_random, exclude: current.value),
        spinning: tick < _tickCount,
      );
      notifyListeners();

      if (tick < _tickCount) {
        _timers[category] = Timer(
          Duration(milliseconds: _baseDelayMs + tick * _delayStepMs),
          flick,
        );
      } else {
        _timers.remove(category);
      }
    }

    _timers[category] = Timer(
      const Duration(milliseconds: _baseDelayMs),
      flick,
    );
  }

  void rollAll() {
    for (final category in DieCategory.values) {
      spin(category);
    }
  }

  /// Captures all six current values — locked or not — as a new entry at the
  /// top of the gallery, then moves to the Gallery tab.
  void saveToGallery() {
    final entry = GalleryEntry(
      id: 'g${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1000)}',
      values: {
        for (final category in DieCategory.values)
          category: _dice[category]!.value,
      },
      rotation: _random.nextDouble() * 3 - 1.5,
    );
    _gallery.insert(0, entry);
    _tab = AppTab.gallery;
    notifyListeners();
    _persist();
  }

  void removeEntry(String id) {
    _gallery.removeWhere((entry) => entry.id == id);
    notifyListeners();
    _persist();
  }

  void attachImage(String id, Uint8List? bytes) {
    final index = _gallery.indexWhere((entry) => entry.id == id);
    if (index == -1) return;
    _gallery[index] = _gallery[index].withImage(bytes);
    notifyListeners();
    _persist();
  }

  /// Loads the stored gallery. Call once before the first frame.
  Future<void> restore() async {
    final store = _store;
    if (store == null) return;

    final stored = await store.load();
    if (stored.isEmpty) return;

    _gallery
      ..clear()
      ..addAll(stored);
    notifyListeners();
  }

  /// Queued behind any write already in flight. Deliberately not awaited by
  /// callers — the UI updates from memory and disk catches up.
  void _persist() {
    final store = _store;
    if (store == null) return;

    final snapshot = List<GalleryEntry>.of(_gallery);
    _writes = _writes.then((_) => store.save(snapshot)).catchError(
      (Object error, StackTrace stack) {
        // A failed write costs this change, not the session.
        debugPrint('Could not save gallery: $error\n$stack');
      },
    );
  }

  @override
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    super.dispose();
  }
}
