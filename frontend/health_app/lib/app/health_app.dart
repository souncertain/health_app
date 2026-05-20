import 'package:flutter/material.dart';

import '../features/auth/presentation/pages/auth_gate_page.dart';

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diplom Health',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.05),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF2FBF3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1DB954),
          primary: const Color(0xFF1DB954),
          secondary: const Color(0xFF3165E6),
          surface: Colors.white,
        ),
        fontFamily: 'SF Pro Display',
      ),
      home: const AuthGatePage(),
    );
  }
}
