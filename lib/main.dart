import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'state/app_state.dart';
import 'theme/tokens.dart';

void main() => runApp(const ArtspirationApp());

/// Drops Android's overscroll stretch, which scales the whole viewport when you
/// pull past an edge — it warps the cards' borders and offset shadows and reads
/// as a rendering fault. Platform scroll physics are left alone, so iOS keeps
/// its native rubber-band.
class _NoOverscrollStretch extends MaterialScrollBehavior {
  const _NoOverscrollStretch();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class ArtspirationApp extends StatelessWidget {
  const ArtspirationApp({super.key, this.state});

  /// Optional pre-built state, used by tests and design previews.
  final ArtspirationState? state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artspiration',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _NoOverscrollStretch(),
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.paper,
        fontFamily: 'Nunito',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.ink,
          surface: AppColors.paper,
        ),
      ),
      home: HomeShell(state: state),
    );
  }
}
