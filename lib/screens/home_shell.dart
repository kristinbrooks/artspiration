import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/bottom_tab_bar.dart';
import '../widgets/paper_background.dart';
import 'gallery_screen.dart';
import 'roll_screen.dart';

/// Scrolling content over paper, with the tab bar pinned to the bottom.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.state});

  /// Injectable so tests and design previews can seed the app. When null the
  /// shell creates and owns its own state.
  final ArtspirationState? state;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final ArtspirationState _state = widget.state ?? ArtspirationState();
  late final bool _ownsState = widget.state == null;

  @override
  void dispose() {
    if (_ownsState) _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The design's 58px top padding clears the status bar on the 393x852 frame
    // it was drawn at; take the device inset when it's larger.
    final topInset = math.max(58.0, MediaQuery.viewPaddingOf(context).top);

    // The Scaffold supplies the Material ancestor that Text and the picker's
    // bottom sheet both need; without it every label falls back to Flutter's
    // yellow-underline debug style.
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: PaperBackground(
        child: ListenableBuilder(
          listenable: _state,
          builder: (context, _) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(18, topInset, 18, 18),
                    child: switch (_state.tab) {
                      AppTab.roll => RollScreen(state: _state),
                      AppTab.gallery => GalleryScreen(state: _state),
                    },
                  ),
                ),
                BottomTabBar(
                  current: _state.tab,
                  onChanged: (tab) => _state.tab = tab,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
