import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/menu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFFFFCF5),
      systemNavigationBarDividerColor: Color(0xFFEDE2CC),
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  runApp(const JapanesePracticeApp());
}

class JapanesePracticeApp extends StatelessWidget {
  const JapanesePracticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFFE8C76A);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '일본어 필기 연습',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        fontFamily: 'Nixgon',
        scaffoldBackgroundColor: const Color(0xFFFFFCF5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Nixgon',
            color: Color(0xFF3C3426),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: Color(0xFF514737),
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF514737),
          ),
          titleMedium: TextStyle(
            color: Color(0xFF3C3426),
            fontWeight: FontWeight.w600,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF574B36),
            side: const BorderSide(
              color: Color(0xFFE6D7B8),
              width: 1,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Nixgon',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE3BE58),
            foregroundColor: const Color(0xFF4A3B1F),
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Nixgon',
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        dividerColor: const Color(0xFFEDE2CC),
        splashColor: seedColor.withOpacity(0.08),
        highlightColor: seedColor.withOpacity(0.04),
      ),
      home: const MenuScreen(),
    );
  }
}
