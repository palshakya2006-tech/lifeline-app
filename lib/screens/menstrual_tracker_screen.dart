import 'package:flutter/material.dart';
import 'pcos_risk_screen.dart';

class MenstrualTrackerScreen extends StatefulWidget {
  const MenstrualTrackerScreen({super.key});
  @override
  State<MenstrualTrackerScreen> createState() => _MenstrualTrackerScreenState();
}

class _MenstrualTrackerScreenState extends State<MenstrualTrackerScreen> {
  DateTime? lastPeriodDate;
  final TextEditingController cycleController = TextEditingController();
  Map<String, String>? resultData;
  bool _showAlert = false;
  String _alertMessage = "";

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => lastPeriodDate = picked);
  }

  void calculateCycle() {
    if (lastPeriodDate == null || cycleController.text.isEmpty) return;
    int cycleLength = int.tryParse(cycleController.text) ?? 28;

    _showAlert = false;
    _alertMessage = "";
    if (cycleLength < 21) {
      _showAlert = true;
      _alertMessage = "⚠️ Your cycle is shorter than 21 days — this may indicate hormonal imbalance or polymenorrhea. Consider consulting a gynecologist.";
    } else if (cycleLength > 35) {
      _showAlert = true;
      _alertMessage = "⚠️ Your cycle is longer than 35 days — this could be a sign of PCOS, stress, or thyroid issues. A medical checkup is recommended.";
    }

    final nextPeriod    = lastPeriodDate!.add(Duration(days: cycleLength));
    final ovulationDate = lastPeriodDate!.add(Duration(days: cycleLength - 14));
    final fertileStart  = ovulationDate.subtract(const Duration(days: 3));
    final fertileEnd    = ovulationDate.add(const Duration(days: 2));
    final daysUntil     = nextPeriod.difference(DateTime.now()).inDays;

    setState(() {
      resultData = {
        "last": "${lastPeriodDate!.day}/${lastPeriodDate!.month}/${lastPeriodDate!.year}",
        "next": "${nextPeriod.day}/${nextPeriod.month}/${nextPeriod.year}",
        "ovulation": "${ovulationDate.day}/${ovulationDate.month}/${ovulationDate.year}",
        "fertile": "${fertileStart.day}/${fertileStart.month} – ${fertileEnd.day}/${fertileEnd.month}",
        "days_until": daysUntil > 0 ? "$daysUntil days away" : daysUntil == 0 ? "Today!" : "Expected ${-daysUntil} days ago",
        "cycle_status": cycleLength >= 21 && cycleLength <= 35 ? "Regular" : "Irregular",
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardBg  = _isDark ? const Color(0xFF141D2E) : Colors.white;
    final surfBg  = _isDark ? const Color(0xFF1A2540) : const Color(0xFFF4F8FB);
    final border  = _isDark ? const Color(0xFF2A3A55) : const Color(0xFFDDE8F0);
    final textPri = _isDark ? Colors.white : const Color(0xFF0D2137);
    final textSec = _isDark ? const Color(0xFF7B9BB8) : const Color(0xFF6B8EA8);

    return Scaffold(
      backgroundColor: _isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text("Cycle Tracker"),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PCOSRiskScreen())),
            icon: const Icon(Icons.biotech, color: Color(0xFFAD1457), size: 18),
            label: const Text("AI Analysis",
                style: TextStyle(color: Color(0xFFAD1457), fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
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
                        Text("Menstrual Cycle Tracker",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        SizedBox(height: 4),
                        Text("Track your cycle, fertility window & get AI health analysis",
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Date picker card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
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
                  Text("Last Period Date",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPri)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                      decoration: BoxDecoration(
                        color: surfBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: lastPeriodDate != null ? const Color(0xFFAD1457) : border,
                            width: lastPeriodDate != null ? 2 : 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFFAD1457), size: 18),
                          const SizedBox(width: 10),
                          Text(
                            lastPeriodDate == null
                                ? "Tap to select date"
                                : "${lastPeriodDate!.day}/${lastPeriodDate!.month}/${lastPeriodDate!.year}",
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: lastPeriodDate != null ? textPri : textSec),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Cycle length card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
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
                  Text("Cycle Length (days)",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textPri)),
                  const SizedBox(height: 4),
                  Text("Normal range: 21–35 days",
                      style: TextStyle(fontSize: 11, color: textSec)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cycleController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textPri),
                    decoration: InputDecoration(
                      hintText: "e.g. 28",
                      hintStyle: TextStyle(color: textSec),
                      filled: true,
                      fillColor: surfBg,
                      prefixIcon: const Icon(Icons.repeat, color: Color(0xFFAD1457), size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFAD1457), width: 2)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: calculateCycle,
                icon: const Icon(Icons.calculate),
                label: const Text("Predict My Cycle"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFAD1457),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Irregularity alert
            if (_showAlert)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(_isDark ? 0.12 : 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text("Cycle Irregularity Detected",
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_alertMessage,
                        style: TextStyle(fontSize: 13, color: textPri, height: 1.5)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const PCOSRiskScreen())),
                        icon: const Icon(Icons.biotech, size: 16, color: Color(0xFFAD1457)),
                        label: const Text("Run AI Health Analysis",
                            style: TextStyle(color: Color(0xFFAD1457), fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFAD1457)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (resultData != null) ...[
              const SizedBox(height: 16),
              _resultCard(),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _resultCard() {
    final isIrregular = resultData!["cycle_status"] == "Irregular";
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFAD1457), Color(0xFFE91E8C)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFFAD1457).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("🔮", style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Text("Cycle Prediction",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  resultData!["cycle_status"]!,
                  style: TextStyle(
                      color: isIrregular ? Colors.yellow : Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text("📅", style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Next Period", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(resultData!["next"]!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                    Text(resultData!["days_until"]!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _resultRow(Icons.circle, "Last Period", resultData!["last"]!),
          _resultRow(Icons.favorite, "Fertile Window", resultData!["fertile"]!),
          _resultRow(Icons.radio_button_checked, "Ovulation", resultData!["ovulation"]!),
          const SizedBox(height: 12),
          const Text(
            "This is an estimated prediction. Cycles may vary. For health concerns, use the AI Analyzer.",
            style: TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: Colors.white60, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}
