import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'risk_predictor_screen.dart';
import 'medicine_scanner_screen.dart';
import 'menstrual_tracker_screen.dart';
import 'medical_history_screen.dart';
import 'health_score_screen.dart';
import 'pcos_risk_screen.dart';
import 'corporate_health_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String gender;
  const DashboardScreen({super.key, required this.gender});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF4F8FB),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection("users").doc(uid).snapshots(),
        builder: (context, snap) {
          Map<String, dynamic> data = {};
          if (snap.hasData && snap.data!.exists) {
            data = snap.data!.data() as Map<String, dynamic>? ?? {};
          }

          final name        = data["name"] ?? "User";
          final bloodGroup  = data["blood_group"] ?? "Unknown";
          final emergency   = data["emergency_contact"] ?? "Not set";
          final email       = FirebaseAuth.instance.currentUser?.email ?? "";
          final healthScore = data["health_score"] as int?;
          final healthGrade = data["health_grade"] as String?;
          final isFemale    = gender == "Female";

          return CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D2137), Color(0xFF1A6B9A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Good ${_greeting()}, 👋",
                                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  name,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(email,
                                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12)),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : "U",
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _miniCard("Blood Group", bloodGroup, Icons.water_drop, Colors.red.shade300),
                          const SizedBox(width: 12),
                          _miniCard(
                              "Emergency",
                              emergency.length > 10 ? "${emergency.substring(0, 10)}…" : emergency,
                              Icons.phone,
                              Colors.green.shade300),
                          const SizedBox(width: 12),
                          _miniCard("Gender", gender, Icons.person, Colors.purple.shade200),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // ── Health Score Card ──────────────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const HealthScoreScreen())),
                      child: _healthScoreCard(healthScore, healthGrade),
                    ),

                    const SizedBox(height: 24),

                    // ── Quick Actions ──────────────────────────────────────
                    Text("Quick Actions",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0D2137))),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.5,
                      children: [
                        _actionCard(context, "🔬 Risk\nPredictor", const Color(0xFF1A6B9A),
                            const Color(0xFF2E9CCA),
                                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiskPredictorScreen()))),
                        _actionCard(context, "💊 Medicine\nScanner", const Color(0xFF2E7D32),
                            const Color(0xFF43A047),
                                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineScannerScreen()))),
                        if (isFemale)
                          _actionCard(context, "🌸 Cycle\nTracker", const Color(0xFFAD1457),
                              const Color(0xFFE91E8C),
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MenstrualTrackerScreen()))),
                        if (isFemale)
                          _actionCard(context, "🔬 Women's\nHealth AI", const Color(0xFF880E4F),
                              const Color(0xFFAD1457),
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PCOSRiskScreen()))),
                        _actionCard(context, "📋 Medical\nHistory", const Color(0xFF6A1B9A),
                            const Color(0xFF9C27B0),
                                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalHistoryScreen()))),
                        _actionCard(context, "🏢 Corporate\nShield", const Color(0xFF37474F),
                            const Color(0xFF546E7A),
                                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CorporateHealthScreen()))),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Recent Medical History ─────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Recent Records",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0D2137))),
                        TextButton(
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const MedicalHistoryScreen())),
                          child: const Text("View All",
                              style: TextStyle(color: Color(0xFF1A6B9A))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("users")
                          .doc(uid)
                          .collection("medical_history")
                          .orderBy("date", descending: true)
                          .limit(3)
                          .snapshots(),
                      builder: (ctx, histSnap) {
                        final cardBg = isDark ? const Color(0xFF141D2E) : Colors.white;
                        if (!histSnap.hasData || histSnap.data!.docs.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: cardBg, borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                const Text("📭", style: TextStyle(fontSize: 28)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "No medical records yet.\nAdd your first record in Medical History.",
                                    style: TextStyle(
                                        color: isDark ? const Color(0xFF7B9BB8) : const Color(0xFF6B8EA8)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Column(
                          children: histSnap.data!.docs.map((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            return _historyTile(d, isDark);
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    _healthTipCard(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _healthScoreCard(int? score, String? grade) {
    final hasScore = score != null && score > 0;
    final Color scoreColor = !hasScore
        ? const Color(0xFF1A6B9A)
        : score >= 85
        ? const Color(0xFF2E7D32)
        : score >= 70
        ? const Color(0xFF558B2F)
        : score >= 55
        ? Colors.orange
        : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasScore
              ? [scoreColor.withOpacity(0.85), scoreColor]
              : [const Color(0xFF1A6B9A), const Color(0xFF2E9CCA)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: scoreColor.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: hasScore ? score / 100 : 0.0,
                  strokeWidth: 7,
                  color: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
                Center(
                  child: Text(
                    hasScore ? "$score" : "?",
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasScore ? "Health Score: $grade" : "Calculate Health Score",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  hasScore
                      ? "Tap to see breakdown & personalized tips"
                      : "Get your dynamic health rating based on vitals & lifestyle",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 16),
        ],
      ),
    );
  }

  Widget _miniCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                textAlign: TextAlign.center),
            Text(label,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(BuildContext context, String title, Color c1, Color c2, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c1, c2]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: c1.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, height: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _historyTile(Map<String, dynamic> d, bool isDark) {
    final cardBg  = isDark ? const Color(0xFF141D2E) : Colors.white;
    final textPri = isDark ? Colors.white : const Color(0xFF0D2137);
    final textSec = isDark ? const Color(0xFF7B9BB8) : const Color(0xFF6B8EA8);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A6B9A).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medical_information, color: Color(0xFF1A6B9A), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d["diagnosis"] ?? "Record",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPri)),
                Text(d["doctor"] ?? "",
                    style: TextStyle(fontSize: 11, color: textSec)),
              ],
            ),
          ),
          Text(d["date"] ?? "", style: TextStyle(fontSize: 11, color: textSec)),
        ],
      ),
    );
  }

  Widget _healthTipCard() {
    final tips = [
      "💧 Drink at least 8 glasses of water daily",
      "🏃 30 minutes of exercise reduces heart disease risk by 35%",
      "😴 7-9 hours of sleep boosts your immune system",
      "🥗 A balanced diet prevents 80% of chronic diseases",
      "🧘 5 minutes of meditation daily reduces cortisol by 20%",
      "🚶 10,000 steps a day keeps lifestyle diseases at bay",
    ];
    tips.shuffle();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A6B9A), Color(0xFF2E9CCA)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Text("💡", style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Health Tip",
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(tips.first,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Morning";
    if (hour < 17) return "Afternoon";
    return "Evening";
  }
}
