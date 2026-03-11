import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LifeLineApp());
}

// ── Theme Notifier — drives dark/light toggle across the whole app ───────────
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setMode(ThemeMode m) {
    _mode = m;
    notifyListeners();
  }
}

// Global notifier — import and use anywhere in the app
final themeNotifier = ThemeNotifier();

class LifeLineApp extends StatefulWidget {
  const LifeLineApp({super.key});
  @override
  State<LifeLineApp> createState() => _LifeLineAppState();
}

class _LifeLineAppState extends State<LifeLineApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeLine',
      debugShowCheckedModeBanner: false,
      themeMode: themeNotifier.mode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const SplashScreen(),
    );
  }

  // ── LIGHT THEME ────────────────────────────────────────────────────────────
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A6B9A),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F8FB),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF4F8FB),
        foregroundColor: Color(0xFF0D2137),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF0D2137),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Color(0xFF0D2137)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A6B9A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF4F8FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDE8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDE8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1A6B9A), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: Color(0xFF6B8EA8)),
      ),
    );
  }

  // ── DARK THEME ─────────────────────────────────────────────────────────────
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E9CCA),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0F1E),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D1626),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E9CCA),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF141D2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A2540),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A3A55)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A3A55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E9CCA), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: Color(0xFF7B9BB8)),
        hintStyle: const TextStyle(color: Color(0xFF4A6080)),
      ),
      dividerColor: const Color(0xFF1E2D44),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Color(0xFFCDD8E8)),
        bodySmall: TextStyle(color: Color(0xFF8AAABB)),
      ),
    );
  }
}

// ── Theme-aware helper — use this throughout the app ─────────────────────────
extension AppTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Card background
  Color get cardBg => isDark ? const Color(0xFF141D2E) : Colors.white;

  // Surface background (fields, chips)
  Color get surfaceBg => isDark ? const Color(0xFF1A2540) : const Color(0xFFF4F8FB);

  // Border color
  Color get borderColor => isDark ? const Color(0xFF2A3A55) : const Color(0xFFDDE8F0);

  // Primary text
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF0D2137);

  // Secondary text
  Color get textSecondary => isDark ? const Color(0xFF7B9BB8) : const Color(0xFF6B8EA8);

  // Primary brand color
  Color get brandColor => isDark ? const Color(0xFF2E9CCA) : const Color(0xFF1A6B9A);

  // Scaffold background
  Color get scaffoldBg => isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF4F8FB);

  // Shadow
  Color get shadowColor => isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.05);
}

// ── AUTH GATE ─────────────────────────────────────────────────────────────────
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        final user = snapshot.data;
        if (user == null || !user.emailVerified) {
          return const LoginScreen();
        }
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection("users").doc(user.uid).get(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }
            String gender = "Male";
            if (snap.hasData && snap.data!.exists) {
              final data = snap.data!.data() as Map<String, dynamic>? ?? {};
              gender = data["gender"] ?? "Male";
            }
            return HomeScreen(gender: gender);
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/lifeline_logo.png", width: 80, height: 80),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Color(0xFF1A6B9A)),
          ],
        ),
      ),
    );
  }
}
