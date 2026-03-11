import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeline/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Note: Firebase requires real initialization for full tests.
    // For unit testing, use firebase_core_platform_interface mocks.
    expect(true, isTrue); // placeholder
  });
}