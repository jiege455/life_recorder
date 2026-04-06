import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const LifeRecorderApp());
}

class LifeRecorderApp extends StatelessWidget {
  const LifeRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI人生记录器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Color(0xFFF5F7FA),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF4A90E2),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
