import '../models/gallery_entry.dart';
import 'app_store_web.dart' if (dart.library.io) 'app_store_io.dart'
    as platform;
import 'categories.dart';

/// Everything that survives a restart.
///
/// Dice values and locks are deliberately absent — those reset on launch, which
/// is what you want from a prompt generator. Which dice are *in play* is a
/// preference rather than a roll, so it does persist.
class StoredState {
  const StoredState({required this.entries, this.enabledDice});

  const StoredState.empty()
      : entries = const [],
        enabledDice = null;

  final List<GalleryEntry> entries;

  /// Null when the stored file predates this setting, which means every die was
  /// in play. An empty set would mean something different and is never written —
  /// at least one die is always enabled.
  final Set<DieCategory>? enabledDice;
}

/// Where app state lives between launches.
///
/// The implementation is chosen at compile time: file-backed on iOS and
/// Android, a no-op on web. `dart:io` cannot be imported into a web build at
/// all, hence the conditional import rather than a runtime `kIsWeb` check.
abstract class AppStore {
  /// Never throws — unreadable or corrupt storage yields empty state rather
  /// than a failed launch.
  Future<StoredState> load();

  /// Writes [state] and drops any image files its entries no longer reference.
  Future<void> save(StoredState state);
}

/// The store for the platform this was compiled for.
AppStore createAppStore() => platform.createStore();
