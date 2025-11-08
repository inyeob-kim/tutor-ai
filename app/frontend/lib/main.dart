import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '과외선생님 행정관리',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.mainNavigation,
      onGenerateRoute: AppRoutes.generateRoute,
      home: const MainNavigationScreen(),
    );
  }
}
