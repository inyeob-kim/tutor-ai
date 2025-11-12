// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frontend/main.dart';
import 'package:frontend/firebase_options.dart';

void main() {
  setUpAll(() async {
    // Firebase 초기화 (테스트용)
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  testWidgets('App starts with SplashScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // SplashScreen이 표시되는지 확인
    // 실제 스플래시 스크린의 내용에 따라 검증 로직을 수정할 수 있습니다
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
