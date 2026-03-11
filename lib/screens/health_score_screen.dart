import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HealthScoreScreen extends StatefulWidget {
  const HealthScoreScreen({super.key});
  @override
  State<HealthScoreScreen> createState() => _HealthScoreScreenState();
}

class _HealthScoreScreenState extends State<HealthScoreScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreAnim;
  late Animation<double> _scoreProgress;

  final _sleepCtrl    = TextEditingController();
  final _stressCtrl   = TextEditingController();
  final _exerciseCtrl = TextEditingController();
  final _waterCtrl    = TextEditingController();

  Map<String, dynamic> _userData  = {};
  Map<String, dynamic> _latestVital = {};
  double _bmi = 0;

  int    _healthScore = 0;
  String _grade       = "";
  Color  _gradeColor  = Colors.green;
  String _summary     = "";
  List<_ScoreFactor> _factors = [];
  bool _loading    = true;
  bool _calculated = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _scoreAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scoreProgress = Tween<double>(begin: 0, end: 0)
        .animate(CurvedAnimation(parent: _scoreAnim, curve: Curves.easeOut));
    _loadData();
  }

  @override
  void dispose() {
    _scoreAnim.dispose();
    _sleepCtrl.dispose();
    _stressCtrl.dispose();
    _exerciseCtrl.dispose();
    _waterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final uDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
      if (uDoc.exists) _userData = uDoc.data() as Map<String, dynamic>;

      final vSnap = await FirebaseFirestore.instance
          .collection("users").doc(uid).collection("vitals")
          .orderBy("recorded_at", descending: true).limit(1).get();
      if (vSnap.docs.isNotEmpty) _latestVital = vSnap.docs.first.data();

      final h = double.tryParse(_userData["height"] ?? "");
      final w = double.tryParse(_userData["weight"] ?? "");
      if (h != null && w != null && h > 0) _bmi = w / pow(h / 100, 2);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _calculate() {
    final sleep    = double.tryParse(_sleepCtrl.text) ?? 0;
    final stress   = int.tryParse(_stressCtrl.text) ?? 5;
    final exercise = double.tryParse(_exerciseCtrl.text) ?? 0;
    final water    = double.tryParse(_waterCtrl.text) ?? 0;

    if (sleep == 0 && exercise == 0 && water == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in your lifestyle inputs"), backgroundColor: Color(0xFFE53935)),
      );
      return;
    }

    double sleepScore  = sleep >= 9 ? 100 : sleep >= 7 ? 100 : sleep >= 6 ? 75 : sleep >= 5 ? 50 : 20;
    double stressScore = stress <= 3 ? 100 : stress <= 5 ? 75 : stress <= 7 ? 50 : 20;
    double exScore     = exercise >= 30 ? 100 : exercise >= 20 ? 80 : exercise >= 10 ? 60 : 30;
    double waterScore  = water >= 8 ? 100 : water >= 6 ? 80 : water >= 4 ? 60 : 40;

    double bmiScore = 100;
    if (_bmi > 0) {
      if (_bmi >= 18.5 && _bmi < 25) bmiScore = 100;
      else if (_bmi >= 25 && _bmi < 30) bmiScore = 65;
      else if (_bmi >= 30) bmiScore = 35;
      else bmiScore = 55;
    }

    double bpScore = 85;
    final bpStr = _latestVital["bp"] as String? ?? "";
    if (bpStr.contains("/")) {
      final parts = bpStr.split("/");
      final sys = int.tryParse(parts[0]) ?? 0;
      final dia = int.tryParse(parts[1]) ?? 0;
      if (sys > 0) {
        if (sys < 120 && dia < 80) bpScore = 100;
        else if (sys < 130 && dia < 85) bpScore = 80;
        else if (sys < 140 && dia < 90) bpScore = 60;
        else bpScore = 30;
      }
    }

    double sugarScore = 85;
    final sugarStr = (_latestVital["sugar"] as String? ?? "").replaceAll(RegExp(r'[^0-9.]'), '');
    final sugar = double.tryParse(sugarStr) ?? 0;
    if (sugar > 0) {
      if (sugar < 100) sugarScore = 100;
      else if (sugar < 126) sugarScore = 70;
      else sugarScore = 35;
    }

    final score = (sleepScore * 0.18 + stressScore * 0.18 + exScore * 0.16 +
        waterScore * 0.12 + bmiScore * 0.16 + bpScore * 0.10 + sugarScore * 0.10)
        .round().clamp(0, 100);

    String grade; Color color; String summary;
    if (score >= 85) {
      grade = "Excellent"; color = const Color(0xFF2E7D32);
      summary = "Your health is in great shape! Keep up the healthy lifestyle.";
    } else if (score >= 70) {
      grade = "Good"; color = const Color(0xFF558B2F);
      summary = "You're doing well. Small improvements in sleep or exercise will boost your score.";
    } else if (score >= 55) {
      grade = "Fair"; color = Colors.orange;
      summary = "There's room to improve. Focus on sleep, hydration and reducing stress.";
    } else if (score >= 40) {
      grade = "Poor"; color = Colors.deepOrange;
      summary = "Your health needs attention. Consider consulting a doctor and improving daily habits.";
    } else {
      grade = "Critical"; color = Colors.red;
      summary = "Please consult a healthcare provider. Multiple health indicators need urgent attention.";
    }

    _factors = [
      _ScoreFactor("😴 Sleep", sleepScore.round(), "${sleep.toStringAsFixed(0)} hrs/night"),
      _ScoreFactor("🧘 Stress", stressScore.round(), "Level $stress/10"),
      _ScoreFactor("🏃 Exercise", exScore.round(), "${exercise.toStringAsFixed(0)} min/day"),
      _ScoreFactor("💧 Hydration", waterScore.round(), "${water.toStringAsFixed(0)} glasses/day"),
      _ScoreFactor("⚖️ BMI", bmiScore.round(), _bmi > 0 ? _bmi.toStringAsFixed(1) : "Not set"),
      _ScoreFactor("❤️ Blood Pressure", bpScore.round(), bpStr.isNotEmpty ? bpStr : "Not logged"),
      _ScoreFactor("🩸 Sugar", sugarScore.round(), sugarStr.isNotEmpty ? "$sugarStr mg/dL" : "Not logged"),
    ];

    setState(() {
      _healthScore = score;
      _grade = grade;
      _gradeColor = color;
      _summary = summary;
      _calculated = true;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection("users").doc(uid).update({
        "health_score": score,
        "health_grade": grade,
        "score_updated": DateTime.now().toIso8601String().substring(0, 10),
      });
    }

    _scoreProgress = Tween<double>(begin: 0, end: score / 100)
        .animate(CurvedAnimation(parent: _scoreAnim, curve: Curves.easeOut));
    _scoreAnim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final cardBg  = _isDark ? const Color(0xFF141D2E) : Colors.white;
    final surfBg  = _isDark ? const Color(0xFF1A2540) : const Color(0xFFF4F8FB);
    final textPri = _isDark ? Colors.white : const Color(0xFF0D2137);
    final textSec = _isDark ? const Color(0xFF7B9BB8) : const Color(0xFF6B8EA8);
    final border  = _isDark ? const Color(0xFF2A3A55) : const Color(0xFFDDE8F0);

    return Scaffold(
      backgroundColor: _isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF4F8FB),
      appBar: AppBar(title: const Text("Health Score")),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A6B9A)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Intro banner — gradient always looks great
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0D2137), Color(0xFF1A6B9A)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Text("🏆", style: TextStyle(fontSize: 32)),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Your LifeLine Health Score",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        SizedBox(height: 4),
                        Text("A dynamic 0–100 score based on your vitals,\nBMI, sleep, stress & lifestyle",
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Inputs card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: _isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                    blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Lifestyle Inputs",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPri)),
                  const SizedBox(height: 4),
                  Text("Fill in your daily habits to get an accurate score",
                      style: TextStyle(fontSize: 12, color: textSec)),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _lifeField(_sleepCtrl, "😴 Sleep (hrs)", "8", surfBg, border, textPri, textSec)),
                    const SizedBox(width: 12),
                    Expanded(child: _lifeField(_stressCtrl, "🧘 Stress (1-10)", "4", surfBg, border, textPri, textSec)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _lifeField(_exerciseCtrl, "🏃 Exercise (min)", "30", surfBg, border, textPri, textSec)),
                    const SizedBox(width: 12),
                    Expanded(child: _lifeField(_waterCtrl, "💧 Water (glasses)", "8", surfBg, border, textPri, textSec)),
                  ]),
                  if (_latestVital.isEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Expanded(child: Text(
                            "Log vitals in Medical History for a more accurate score",
                            style: TextStyle(fontSize: 11, color: Colors.orange),
                          )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: const Text("Calculate My Health Score"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            if (_calculated) ...[
              const SizedBox(height: 28),
              // Score ring card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(
                      color: _isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.06),
                      blurRadius: 15)],
                ),
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _scoreProgress,
                      builder: (_, __) => SizedBox(
                        width: 160, height: 160,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: _scoreProgress.value,
                              strokeWidth: 14,
                              color: _gradeColor,
                              backgroundColor: _gradeColor.withOpacity(0.12),
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${(_scoreProgress.value * 100).round()}",
                                    style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: _gradeColor),
                                  ),
                                  Text("/ 100", style: TextStyle(fontSize: 14, color: _gradeColor.withOpacity(0.6), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(_grade, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _gradeColor)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _gradeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(_summary,
                          style: TextStyle(fontSize: 13, color: _gradeColor, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Factors card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                      color: _isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                      blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Score Breakdown",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPri)),
                    const SizedBox(height: 16),
                    ..._factors.map((f) => _factorRow(f, textPri, textSec)),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _tipsCard(),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _factorRow(_ScoreFactor f, Color textPri, Color textSec) {
    final color = f.score >= 80 ? const Color(0xFF2E7D32) : f.score >= 60 ? Colors.orange : Colors.red;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(f.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPri)),
              Row(children: [
                Text(f.detail, style: TextStyle(fontSize: 11, color: textSec)),
                const SizedBox(width: 8),
                Text("${f.score}", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
              ]),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: f.score / 100,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipsCard() {
    final tips = <String>[];
    for (final f in _factors) {
      if (f.score < 60) {
        if (f.label.contains("Sleep"))    tips.add("😴 Aim for 7–9 hours of sleep each night");
        if (f.label.contains("Stress"))   tips.add("🧘 Try meditation or breathing exercises to reduce stress");
        if (f.label.contains("Exercise")) tips.add("🏃 Start with 20–30 min of brisk walking daily");
        if (f.label.contains("Hydration"))tips.add("💧 Drink at least 8 glasses of water every day");
        if (f.label.contains("BMI"))      tips.add("⚖️ Consult a dietician for a personalized meal plan");
        if (f.label.contains("Blood"))    tips.add("❤️ Monitor your BP regularly and reduce salt intake");
        if (f.label.contains("Sugar"))    tips.add("🩸 Reduce refined carbs and sugar; consider a glucose test");
      }
    }
    if (tips.isEmpty) tips.add("🌟 Keep up your excellent healthy habits!");

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A6B9A), Color(0xFF2E9CCA)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text("💡", style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text("Personalized Tips",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          ]),
          const SizedBox(height: 12),
          ...tips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("•", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _lifeField(TextEditingController ctrl, String label, String hint,
      Color surfBg, Color border, Color textPri, Color textSec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPri)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: TextStyle(color: textPri),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textSec),
            filled: true,
            fillColor: surfBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A6B9A), width: 2)),
          ),
        ),
      ],
    );
  }
}

class _ScoreFactor {
  final String label;
  final int score;
  final String detail;
  _ScoreFactor(this.label, this.score, this.detail);
}
