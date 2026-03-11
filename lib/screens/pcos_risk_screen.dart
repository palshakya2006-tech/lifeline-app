import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PCOSRiskScreen extends StatefulWidget {
  const PCOSRiskScreen({super.key});
  @override
  State<PCOSRiskScreen> createState() => _PCOSRiskScreenState();
}

class _PCOSRiskScreenState extends State<PCOSRiskScreen> {
  int _cycleIrregularity = 0;
  int _flowIntensity     = 1;
  int _fatigueLevel      = 0;
  int _acneLevel         = 0;
  int _hairGrowth        = 0;
  int _weightGain        = 0;
  int _moodSwings        = 0;
  int _painLevel         = 1;
  int _familyHistory     = 0;

  bool _analyzed = false;
  List<_RiskResult> _results = [];

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  void _analyze() {
    int pcosScore = 0;
    if (_cycleIrregularity == 1) pcosScore += 20;
    if (_cycleIrregularity == 2) pcosScore += 40;
    if (_acneLevel == 1) pcosScore += 10;
    if (_acneLevel >= 2) pcosScore += 20;
    if (_hairGrowth == 1) pcosScore += 20;
    if (_weightGain == 1) pcosScore += 15;
    if (_moodSwings == 1) pcosScore += 5;
    if (_moodSwings == 2) pcosScore += 10;
    if (_familyHistory == 1) pcosScore += 15;
    pcosScore = pcosScore.clamp(0, 100);

    int anemiaScore = 0;
    if (_flowIntensity == 2) anemiaScore += 25;
    if (_flowIntensity == 3) anemiaScore += 50;
    if (_fatigueLevel == 1) anemiaScore += 10;
    if (_fatigueLevel == 2) anemiaScore += 25;
    if (_fatigueLevel == 3) anemiaScore += 40;
    if (_familyHistory == 1) anemiaScore += 10;
    anemiaScore = anemiaScore.clamp(0, 100);

    int hormonalScore = 0;
    if (_cycleIrregularity >= 1) hormonalScore += 20;
    if (_moodSwings == 2) hormonalScore += 20;
    if (_acneLevel >= 2) hormonalScore += 15;
    if (_hairGrowth == 1) hormonalScore += 20;
    if (_painLevel == 3) hormonalScore += 15;
    if (_familyHistory == 1) hormonalScore += 10;
    hormonalScore = hormonalScore.clamp(0, 100);

    _results = [
      _RiskResult(
        title: "PCOS Risk", emoji: "🔬", score: pcosScore,
        description: pcosScore >= 60
            ? "High probability of PCOS. Key indicators detected: cycle irregularity, hormonal symptoms."
            : pcosScore >= 30
            ? "Moderate PCOS risk. Monitor symptoms and consider ultrasound screening."
            : "Low PCOS risk based on current symptoms.",
        color: pcosScore >= 60 ? Colors.red : pcosScore >= 30 ? Colors.orange : const Color(0xFF2E7D32),
        advice: pcosScore >= 60
            ? "Consult a gynecologist urgently. Consider hormonal blood panel & pelvic ultrasound."
            : pcosScore >= 30
            ? "Schedule a checkup. Maintain healthy BMI and reduce sugar intake."
            : "Continue regular checkups. Maintain a healthy diet and active lifestyle.",
      ),
      _RiskResult(
        title: "Anemia Risk", emoji: "🩸", score: anemiaScore,
        description: anemiaScore >= 60
            ? "High anemia risk. Heavy flow and severe fatigue are strong indicators of iron deficiency."
            : anemiaScore >= 30
            ? "Moderate anemia risk. Consider iron-rich diet and hemoglobin test."
            : "Low anemia risk based on your inputs.",
        color: anemiaScore >= 60 ? Colors.red : anemiaScore >= 30 ? Colors.orange : const Color(0xFF2E7D32),
        advice: anemiaScore >= 60
            ? "Get a CBC blood test. Doctor may prescribe iron supplements."
            : anemiaScore >= 30
            ? "Increase iron-rich foods: spinach, lentils, red meat. Monitor fatigue."
            : "Good! Maintain iron-rich diet to keep levels optimal.",
      ),
      _RiskResult(
        title: "Hormonal Imbalance", emoji: "⚗️", score: hormonalScore,
        description: hormonalScore >= 60
            ? "Strong hormonal imbalance indicators. Multiple symptoms aligned with estrogen/androgen imbalance."
            : hormonalScore >= 30
            ? "Possible hormonal fluctuations. Could be lifestyle or early-stage imbalance."
            : "Hormonal profile appears normal based on symptoms.",
        color: hormonalScore >= 60 ? Colors.purple : hormonalScore >= 30 ? Colors.orange : const Color(0xFF2E7D32),
        advice: hormonalScore >= 60
            ? "Hormone panel test recommended. Consult endocrinologist or gynecologist."
            : hormonalScore >= 30
            ? "Reduce stress, improve sleep quality. Yoga and Omega-3 can help balance hormones."
            : "Maintain healthy lifestyle. Avoid crash diets and excessive stress.",
      ),
    ];

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection("users").doc(uid).collection("health_analyses").add({
        "type": "PCOS_Anemia_Hormonal",
        "pcos_score": pcosScore,
        "anemia_score": anemiaScore,
        "hormonal_score": hormonalScore,
        "analyzed_at": Timestamp.now(),
        "date": "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
      });
    }

    setState(() => _analyzed = true);
  }

  @override
  Widget build(BuildContext context) {
    final cardBg  = _isDark ? const Color(0xFF141D2E) : Colors.white;
    final textPri = _isDark ? Colors.white : const Color(0xFF0D2137);
    final textSec = _isDark ? const Color(0xFF7B9BB8) : const Color(0xFF6B8EA8);

    return Scaffold(
      backgroundColor: _isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF4F8FB),
      appBar: AppBar(title: const Text("Women's Health AI Analyzer")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFAD1457), Color(0xFFE91E8C)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Text("🌸", style: TextStyle(fontSize: 32)),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("AI Women's Health Analysis",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        SizedBox(height: 4),
                        Text("Detects PCOS, Anemia & Hormonal\nimbalance risk from your symptoms",
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Input card
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
                  Text("Symptom Assessment",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPri)),
                  const SizedBox(height: 4),
                  Text("Answer honestly for accurate analysis",
                      style: TextStyle(fontSize: 12, color: textSec)),
                  const SizedBox(height: 20),

                  _segmentQuestion("Cycle Regularity", ["Regular", "Slightly Irregular", "Very Irregular"],
                      _cycleIrregularity, (v) => setState(() => _cycleIrregularity = v), textPri, textSec),
                  _segmentQuestion("Menstrual Flow", ["Light", "Normal", "Heavy", "Very Heavy"],
                      _flowIntensity, (v) => setState(() => _flowIntensity = v), textPri, textSec),
                  _segmentQuestion("Fatigue Level", ["None", "Mild", "Moderate", "Severe"],
                      _fatigueLevel, (v) => setState(() => _fatigueLevel = v), textPri, textSec),
                  _segmentQuestion("Acne Severity", ["None", "Mild", "Moderate", "Severe"],
                      _acneLevel, (v) => setState(() => _acneLevel = v), textPri, textSec),
                  _segmentQuestion("Period Pain", ["None", "Mild", "Moderate", "Severe"],
                      _painLevel, (v) => setState(() => _painLevel = v), textPri, textSec),
                  _segmentQuestion("Mood Swings", ["None", "Mild", "Severe"],
                      _moodSwings, (v) => setState(() => _moodSwings = v), textPri, textSec),
                  _yesNoQuestion("Excess facial / body hair?", _hairGrowth,
                          (v) => setState(() => _hairGrowth = v), textPri),
                  _yesNoQuestion("Unexplained weight gain?", _weightGain,
                          (v) => setState(() => _weightGain = v), textPri),
                  _yesNoQuestion("Family history of PCOS / hormonal issues?", _familyHistory,
                          (v) => setState(() => _familyHistory = v), textPri),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _analyze,
                icon: const Icon(Icons.biotech),
                label: const Text("Analyze My Health"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAD1457),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            if (_analyzed) ...[
              const SizedBox(height: 24),
              ..._results.map((r) => _resultCard(r, cardBg, textPri)),
              const SizedBox(height: 12),
              _disclaimer(textSec),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _segmentQuestion(String label, List<String> options, int value,
      ValueChanged<int> onChanged, Color textPri, Color textSec) {
    final inactiveBg = _isDark ? const Color(0xFF1A2540) : const Color(0xFFF4F8FB);
    final inactiveBorder = _isDark ? const Color(0xFF2A3A55) : const Color(0xFFDDE8F0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPri)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: options.asMap().entries.map((e) {
              final active = value == e.key;
              return GestureDetector(
                onTap: () => onChanged(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFAD1457) : inactiveBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? const Color(0xFFAD1457) : inactiveBorder),
                  ),
                  child: Text(e.value, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: active ? Colors.white : textSec)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _yesNoQuestion(String label, int value, ValueChanged<int> onChanged, Color textPri) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPri))),
          const SizedBox(width: 12),
          _toggleBtn("No", value == 0, () => onChanged(0)),
          const SizedBox(width: 8),
          _toggleBtn("Yes", value == 1, () => onChanged(1), activeColor: const Color(0xFFAD1457)),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap, {Color activeColor = const Color(0xFF1A6B9A)}) {
    final inactiveBg = _isDark ? const Color(0xFF1A2540) : const Color(0xFFF4F8FB);
    final inactiveBorder = _isDark ? const Color(0xFF2A3A55) : const Color(0xFFDDE8F0);
    final textSec = _isDark ? const Color(0xFF7B9BB8) : const Color(0xFF6B8EA8);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? activeColor : inactiveBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? activeColor : inactiveBorder),
        ),
        child: Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: active ? Colors.white : textSec)),
      ),
    );
  }

  Widget _resultCard(_RiskResult r, Color cardBg, Color textPri) {
    final level = r.score >= 60 ? "High" : r.score >= 30 ? "Moderate" : "Low";
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: _isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: r.color.withOpacity(_isDark ? 0.2 : 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(r.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(child: Text(r.title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: r.color))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${r.score}%", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: r.color)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: r.color, borderRadius: BorderRadius.circular(8)),
                      child: Text(level,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: r.score / 100,
                minHeight: 8,
                backgroundColor: r.color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(r.color),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.description, style: TextStyle(fontSize: 13, color: textPri, height: 1.5)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: r.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: r.color.withOpacity(0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.medical_services_outlined, color: r.color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(r.advice,
                          style: TextStyle(fontSize: 12, color: r.color, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _disclaimer(Color textSec) {
    final bg = _isDark ? const Color(0xFF1A2540) : Colors.grey.shade100;
    final border = _isDark ? const Color(0xFF2A3A55) : Colors.grey.shade300;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: textSec, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "This is an AI-based risk assessment tool, not a medical diagnosis. Always consult a qualified gynecologist or doctor for proper evaluation and treatment.",
              style: TextStyle(fontSize: 11, color: textSec),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskResult {
  final String title, emoji, description, advice;
  final int score;
  final Color color;
  _RiskResult({required this.title, required this.emoji, required this.score,
    required this.description, required this.color, required this.advice});
}
