import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CorporateHealthScreen extends StatefulWidget {
  const CorporateHealthScreen({super.key});
  @override
  State<CorporateHealthScreen> createState() => _CorporateHealthScreenState();
}

class _CorporateHealthScreenState extends State<CorporateHealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic> _userData = {};
  bool _loading = true;

  final Map<String, dynamic> _orgStats = {
    "org_name": "Your Organization",
    "total_users": 247,
    "org_health_score": 68,
    "burnout_risk": 42,
    "high_stress_pct": 38,
    "avg_bmi_normal_pct": 61,
    "anemia_risk_pct": 29,
    "high_bp_pct": 22,
    "active_users_pct": 74,
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadUser();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
      if (doc.exists) _userData = doc.data() as Map<String, dynamic>;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text("Corporate Health Shield"),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFF1A6B9A),
          labelColor: const Color(0xFF1A6B9A),
          unselectedLabelColor: isDark ? const Color(0xFF7B9BB8) : Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.business, size: 18), text: "Org Dashboard"),
            Tab(icon: Icon(Icons.person, size: 18), text: "My Contribution"),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A6B9A)))
          : TabBarView(
        controller: _tabs,
        children: [
          _OrgTab(stats: _orgStats, isDark: isDark),
          _MyContributionTab(userData: _userData, isDark: isDark),
        ],
      ),
    );
  }
}

// ── ORG TAB ────────────────────────────────────────────────────────────────────
class _OrgTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isDark;
  const _OrgTab({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg  = isDark ? const Color(0xFF141D2E) : Colors.white;
    final textPri = isDark ? Colors.white : const Color(0xFF0D2137);
    final textSec = isDark ? const Color(0xFF7B9BB8) : const Color(0xFF6B8EA8);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Org Score hero — gradient always works great
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D2137), Color(0xFF1A6B9A)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(
                  color: const Color(0xFF1A6B9A).withOpacity(0.4),
                  blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.business_center, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stats["org_name"],
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                          Text("${stats["total_users"]} active members",
                              style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: const Text("Demo Mode",
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100, height: 100,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: stats["org_health_score"] / 100,
                            strokeWidth: 10,
                            color: Colors.white,
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("${stats["org_health_score"]}",
                                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                                const Text("/ 100", style: TextStyle(color: Colors.white60, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Org Health Score",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 6),
                        _statLine("⚠️ Burnout Risk", "${stats["burnout_risk"]}%"),
                        _statLine("😰 High Stress", "${stats["high_stress_pct"]}% members"),
                        _statLine("✅ Active Users", "${stats["active_users_pct"]}%"),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text("🔥 Risk Heatmap",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPri)),
          const SizedBox(height: 4),
          Text("Anonymous aggregate health insights across your organization",
              style: TextStyle(fontSize: 12, color: textSec)),
          const SizedBox(height: 16),

          _riskCard("🧘 Stress & Burnout Risk", stats["burnout_risk"],
              "Employees aged 22–32 show highest burnout indicators", Colors.orange, cardBg, textPri, textSec, isDark),
          _riskCard("💗 Cardiovascular Risk", stats["high_bp_pct"],
              "Elevated BP detected in a portion of members", Colors.red, cardBg, textPri, textSec, isDark),
          _riskCard("🩸 Anemia Risk (Women)", stats["anemia_risk_pct"],
              "Based on fatigue + cycle irregularity patterns", const Color(0xFFAD1457), cardBg, textPri, textSec, isDark),
          _riskCard("⚖️ Healthy BMI Range", stats["avg_bmi_normal_pct"],
              "Members with normal BMI — room for lifestyle programs", const Color(0xFF2E7D32), cardBg, textPri, textSec, isDark),

          const SizedBox(height: 24),

          // B2B pitch
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00695C), Color(0xFF00897B)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text("💼", style: TextStyle(fontSize: 24)),
                    SizedBox(width: 10),
                    Expanded(child: Text("LifeLine for Business",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
                  ],
                ),
                const SizedBox(height: 14),
                _bizRow("📊 Real-time org health analytics"),
                _bizRow("🔔 Early burnout & illness alerts"),
                _bizRow("📉 Reduce sick leaves by up to 35%"),
                _bizRow("💰 ₹99–₹199/employee/month"),
                _bizRow("🏥 Insurance partner integrations"),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "\"LifeLine doesn't just react to emergencies — it predicts them across your entire workforce.\"",
                    style: TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _statLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _riskCard(String title, int pct, String detail, Color color,
      Color cardBg, Color textPri, Color textSec, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
            blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPri))),
              Text("$pct%", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(detail, style: TextStyle(fontSize: 12, color: textSec)),
        ],
      ),
    );
  }

  Widget _bizRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── MY CONTRIBUTION TAB ──────────────────────────────────────────────────────
class _MyContributionTab extends StatelessWidget {
  final Map<String, dynamic> userData;
  final bool isDark;
  const _MyContributionTab({required this.userData, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final score        = userData["health_score"] as int? ?? 0;
    final grade        = userData["health_grade"] as String? ?? "Not calculated";
    final name         = userData["name"] as String? ?? "You";
    final scoreUpdated = userData["score_updated"] as String? ?? "";

    final cardBg  = isDark ? const Color(0xFF141D2E) : Colors.white;
    final textPri = isDark ? Colors.white : const Color(0xFF0D2137);
    final textSec = isDark ? const Color(0xFF7B9BB8) : const Color(0xFF6B8EA8);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D2137), Color(0xFF1A6B9A)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : "?",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(
                          score > 0 ? "Health Score: $score — $grade" : "Calculate your Health Score",
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      if (scoreUpdated.isNotEmpty)
                        Text("Updated: $scoreUpdated", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                  blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Your Anonymous Data Contribution",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPri)),
                const SizedBox(height: 4),
                Text(
                    "Your data is anonymized and contributes to org-level health insights. "
                        "No personally identifiable information is ever shared.",
                    style: TextStyle(fontSize: 12, color: textSec)),
                const SizedBox(height: 16),
                _contributionRow("Health Score", score > 0 ? "$score / 100" : "Not set",
                    Icons.star, const Color(0xFF1A6B9A), textPri),
                _contributionRow("Blood Group", userData["blood_group"] ?? "—",
                    Icons.water_drop, Colors.red, textPri),
                _contributionRow("BMI Status", _bmiLabel(userData),
                    Icons.monitor_weight_outlined, Colors.orange, textPri),
                _contributionRow("Vitals Logged", "Synced to aggregate",
                    Icons.favorite, const Color(0xFF2E7D32), textPri),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A6B9A).withOpacity(isDark ? 0.15 : 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1A6B9A).withOpacity(0.25)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.privacy_tip_outlined, color: Color(0xFF1A6B9A), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Privacy First: All organizational analytics use fully anonymized, aggregated data. "
                        "Your individual health records are encrypted and never shared with employers.",
                    style: TextStyle(fontSize: 12, color: Color(0xFF1A6B9A)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _bmiLabel(Map<String, dynamic> data) {
    final h = double.tryParse(data["height"] ?? "");
    final w = double.tryParse(data["weight"] ?? "");
    if (h == null || w == null || h == 0) return "Not set";
    final bmi = w / pow(h / 100, 2);
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25)   return "Normal";
    if (bmi < 30)   return "Overweight";
    return "Obese";
  }

  Widget _contributionRow(String label, String value, IconData icon, Color color, Color textPri) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPri))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
