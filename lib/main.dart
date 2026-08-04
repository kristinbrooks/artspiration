import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'state/app_state.dart';
import 'theme/tokens.dart';

void main() => runApp(const ArtspirationApp());

class ArtspirationApp extends StatelessWidget {
  const ArtspirationApp({super.key, this.state});

  /// Optional pre-built state, used by tests and design previews.
  final ArtspirationState? state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artspiration',
      debugShowCheckedModeBanner: false,
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
