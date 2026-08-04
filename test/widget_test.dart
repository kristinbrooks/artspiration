import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artspiration/data/categories.dart';
import 'package:artspiration/main.dart';
import 'package:artspiration/state/app_state.dart';

/// Long enough for a full flicker chain (7 ticks, ~805ms) to settle.
const _rollSettled = Duration(seconds: 2);

/// The frame the design was drawn at. The roll screen's content is taller than
/// the default 800x600 test surface, which would leave the save button
/// unhittable below the fold.
const _phone = Size(393, 852);

Future<void> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const ArtspirationApp());
  await tester.pump();
}

void main() {
  group('ArtspirationState', () {
    test('starts on the roll tab with every die unlocked and populated', () {
      final state = ArtspirationState(random: math.Random(1));
      addTearDown(state.dispose);

      expect(state.tab, AppTab.roll);
      expect(state.gallery, isEmpty);
      for (final category in DieCategory.values) {
        final die = state.die(category);
        expect(category.options, contains(die.value));
        expect(die.locked, isFalse);
        expect(die.spinning, isFalse);
      }
    });

    test('a locked die is skipped by both reroll and roll all', () {
      fakeAsync((clock) {
        final state = ArtspirationState(random: math.Random(2));
        addTearDown(state.dispose);

        state.toggleLock(DieCategory.mood);
        final locked = state.die(DieCategory.mood).value;

        state.spin(DieCategory.mood);
        clock.elapse(_rollSettled);
        expect(state.die(DieCategory.mood).value, locked);

        state.rollAll();
        clock.elapse(_rollSettled);
        expect(state.die(DieCategory.mood).value, locked);
      });
    });

    test('saving captures all six values and switches to the gallery', () {
      final state = ArtspirationState(random: math.Random(3));
      addTearDown(state.dispose);

      final expected = {
        for (final category in DieCategory.values)
          category: state.die(category).value,
      };

      state.saveToGallery();

      expect(state.tab, AppTab.gallery);
      expect(state.gallery, hasLength(1));
      expect(state.gallery.single.values, expected);
      expect(state.gallery.single.rotation, inInclusiveRange(-1.5, 1.5));
    });

    test('newest entries land on top and remove deletes only its own', () {
      final state = ArtspirationState(random: math.Random(4));
      addTearDown(state.dispose);

      state.saveToGallery();
      final first = state.gallery.single.id;
      state.saveToGallery();
      final second = state.gallery.first.id;

      expect(state.gallery.map((e) => e.id), [second, first]);

      state.removeEntry(first);
      expect(state.gallery.map((e) => e.id), [second]);
    });
  });

  testWidgets('rolling a die marks it spinning, then settles', (tester) async {
    final state = ArtspirationState(random: math.Random(5));
    addTearDown(state.dispose);

    state.spin(DieCategory.medium);
    expect(state.die(DieCategory.medium).spinning, isTrue);

    await tester.pump(_rollSettled);
    expect(state.die(DieCategory.medium).spinning, isFalse);
    expect(DieCategory.medium.options, contains(state.die(DieCategory.medium).value));
  });

  testWidgets('app boots to the roll screen showing every category',
      (tester) async {
    await _pumpApp(tester);

    for (final category in DieCategory.values) {
      expect(find.text(category.label.toUpperCase()), findsOneWidget);
    }
    expect(find.text('Roll All Dice'), findsOneWidget);
    expect(find.text('+ Save this roll to Gallery'), findsOneWidget);
  });

  testWidgets('saving from the roll screen shows the entry in the gallery',
      (tester) async {
    await _pumpApp(tester);

    // The test font is wider than Nunito/Kalam, so the button can sit below
    // the fold even at phone size — scroll it into view before tapping.
    final save = find.text('+ Save this roll to Gallery');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();

    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('Your Gallery'), findsOneWidget);
    expect(find.text('1 saved roll'), findsOneWidget);
    expect(find.text('Nothing here yet!'), findsNothing);
  });

  testWidgets('gallery starts empty', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Gallery'));
    await tester.pumpAndSettle();

    expect(find.text('No saved rolls yet'), findsOneWidget);
    expect(find.text('Nothing here yet!'), findsOneWidget);
  });
}
