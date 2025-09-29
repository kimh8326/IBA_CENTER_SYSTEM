// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pilates_center_client/main.dart';

void main() {
  testWidgets('App starts test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PilatesCenterApp());

    // Verify that the app starts with the login screen
    expect(find.text('필라테스 센터'), findsOneWidget);
  });
}
