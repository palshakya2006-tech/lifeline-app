import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'risk_predictor_screen.dart';
import 'medicine_scanner_screen.dart';
import 'menstrual_tracker_screen.dart';
import 'bmi_calculator_screen.dart';
import 'first_aid_screen.dart';
import 'health_wallet_screen.dart';
import 'health_score_screen.dart';
import 'pcos_risk_screen.dart';
import 'corporate_health_screen.dart';

class HealthFeaturesScreen extends StatefulWidget {
  const HealthFeaturesScreen({super.key});
  @override
  State<HealthFeaturesScreen> createState() => _HealthFeaturesScreenState();
}

class _HealthFeaturesScreenState extends State<HealthFeaturesScreen> {
  String _gender = "Male";
  bool _loading  = true;

  @override
  void initState() {
    super.initState();
    _loadGender();
  }

  Future<void> _loadGender() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _gender = (doc.data() as Map<String, dynamic>)["gender"] ?? "Male";
          });
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF4F8FB),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF1A6B9A))),
      );
    }

    final isFemale = _gender == "Female";

    final features = <_Feature>[
      _Feature("🏆 Health Score", "Dynamic 0–100 score based on your vitals & lifestyle",
          const Color(0xFF1A6B9A), const Color(0xFF2E9CCA), const HealthScoreScreen()),
      _Feature("🔬 AI Risk Predictor", "Analyze health risk based on vitals",
          const Color(0xFF0D2137), const Color(0xFF1A6B9A), const RiskPredictorScreen()),
      _Feature("💊 Medicine Scanner", "Search Indian medicines with full details",
          const Color(0xFF2E7D32), const Color(0xFF43A047), const MedicineScannerScreen()),
      if (isFemale) ...[
        _Feature("🌸 Cycle Tracker", "Track menstrual cycle & fertility window",
            const Color(0xFFAD1457), const Color(0xFFE91E8C), const MenstrualTrackerScreen()),
        _Feature("🔬 Women's Health AI", "PCOS, Anemia & Hormonal risk analysis",
            const Color(0xFF880E4F), const Color(0xFFAD1457), const PCOSRiskScreen()),
      ],
      _Feature("⚖️ BMI Calculator", "Calculate your Body Mass Index",
          const Color(0xFF6A1B9A), const Color(0xFF9C27B0), const BMICalculatorScreen()),
      _Feature("🩺 First Aid Guide", "Emergency first aid procedures",
          const Color(0xFFBF360C), const Color(0xFFFF5722), const FirstAidScreen()),
      _Feature("🔐 Health Wallet", "QR code with your critical health data",
          const Color(0xFF00695C), const Color(0xFF00897B), const HealthWalletScreen()),
      _Feature("🏢 Corporate Health Shield", "Anonymous org health analytics — B2B feature",
          const Color(0xFF37474F), const Color(0xFF546E7A), const CorporateHealthScreen()),
    ];

    final textPri = isDark ? Colors.white : const Color(0xFF0D2137);
    final textSec = isDark ? const Color(0xFF7B9BB8) : const Color(0xFF6B8EA8);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF4F8FB),
      appBar: AppBar(title: const Text("Health Tools")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "All Features",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPri),
            ),
            const SizedBox(height: 4),
            Text(
              "Your personal health toolkit — ${features.length} tools",
              style: TextStyle(fontSize: 13, color: textSec),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: features.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (ctx, i) => _FeatureTile(feature: features[i], isDark: isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature {
  final String title, subtitle;
  final Color c1, c2;
  final Widget screen;
  _Feature(this.title, this.subtitle, this.c1, this.c2, this.screen);
}

class _FeatureTile extends StatelessWidget {
  final _Feature feature;
  final bool isDark;
  const _FeatureTile({super.key, required this.feature, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg  = isDark ? const Color(0xFF141D2E) : Colors.white;
    final textPri = isDark ? Colors.white : const Color(0xFF0D2137);
    final textSec = isDark ? const Color(0xFF7B9BB8) : const Color(0xFF6B8EA8);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => feature.screen)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [feature.c1, feature.c2]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(feature.title.split(" ")[0], style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title.substring(feature.title.indexOf(" ") + 1),
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textPri),
                  ),
                  const SizedBox(height: 4),
                  Text(feature.subtitle, style: TextStyle(fontSize: 12, color: textSec)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: feature.c1.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_forward_ios, size: 14, color: feature.c1),
            ),
          ],
        ),
      ),
    );
  }
}
