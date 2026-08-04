import 'app_store.dart';

/// Web has no `dart:io`, and the browser targets exist only for design
/// verification — so nothing persists there. That's a known limit, not a
/// failure path.
class NoopAppStore implements AppStore {
  const NoopAppStore();

  @override
  Future<StoredState> load() async => const StoredState.empty();

  @override
  Future<void> save(StoredState state) async {}
}

AppStore createStore() => const NoopAppStore();
