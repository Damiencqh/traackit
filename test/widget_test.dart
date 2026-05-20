// Smoke test: the app boots and shows the greeting.
//
// More meaningful tests come later — once the camera & timelapse
// modules stabilise, we'll add unit tests for project state and
// widget tests for the home screen.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:traackit/app.dart';

void main() {
  testWidgets('Traackit boots and shows the greeting', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: TraackitApp()),
    );
    await tester.pump();

    // The greeting always starts with "Hi,"
    expect(find.textContaining('Hi'), findsWidgets);
  });
}
