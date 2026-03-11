import 'package:flutter/material.dart';
import '../screens/emergency_screen.dart';
import '../screens/risk_predictor_screen.dart';
import '../screens/medicine_scanner_screen.dart';
import '../screens/menstrual_tracker_screen.dart';
import '../screens/medical_history_screen.dart';
import '../screens/bmi_calculator_screen.dart';
import '../screens/first_aid_screen.dart';
import '../screens/health_wallet_screen.dart';

class FeatureCard extends StatelessWidget {
  final String title;
  final String? emoji;
  final Color? color1;
  final Color? color2;

  const FeatureCard({
    super.key,
    required this.title,
    this.emoji,
    this.color1,
    this.color2,
  });

  void _navigate(BuildContext context) {
    Widget? screen;

    if (title.contains("Emergency")) screen = const EmergencyScreen();
    else if (title.contains("Risk Predictor")) screen = const RiskPredictorScreen();
    else if (title.contains("Medicine Scanner")) screen = const MedicineScannerScreen();
    else if (title.contains("Menstrual") || title.contains("Cycle")) screen = const MenstrualTrackerScreen();
    else if (title.contains("Medical History") || title.contains("History")) screen = const MedicalHistoryScreen();
    else if (title.contains("BMI")) screen = const BMICalculatorScreen();
    else if (title.contains("First Aid")) screen = const FirstAidScreen();
    else if (title.contains("Health Wallet") || title.contains("QR")) screen = const HealthWalletScreen();

    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c1 = color1 ?? const Color(0xFF1A6B9A);
    final c2 = color2 ?? const Color(0xFF2E9CCA);

    return GestureDetector(
      onTap: () => _navigate(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c1, c2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: c1.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background decoration circle
            Positioned(
              top: -10,
              right: -10,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (emoji != null) ...[
                    Text(emoji!, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    title,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}