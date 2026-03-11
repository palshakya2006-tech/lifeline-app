import 'dart:math';
import 'package:flutter/material.dart';

class BMICalculatorScreen extends StatefulWidget {
  const BMICalculatorScreen({super.key});
  @override
  State<BMICalculatorScreen> createState() => _BMICalculatorScreenState();
}

class _BMICalculatorScreenState extends State<BMICalculatorScreen> {
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  double? _bmi;
  String _category = "";
  Color _color = Colors.green;
  String _advice = "";

  void _calculate() {
    final h = double.tryParse(_heightCtrl.text);
    final w = double.tryParse(_weightCtrl.text);
    if (h == null || w == null || h <= 0) return;

    final hm = h / 100;
    final bmi = w / pow(hm, 2);

    String cat; Color col; String advice;
    if (bmi < 18.5) {
      cat = "Underweight"; col = Colors.blue;
      advice = "Consider increasing caloric intake with nutritious foods. Consult a dietician.";
    } else if (bmi < 25) {
      cat = "Normal Weight"; col = const Color(0xFF2E7D32);
      advice = "Great job! Maintain your healthy lifestyle with regular exercise and balanced diet.";
    } else if (bmi < 30) {
      cat = "Overweight"; col = Colors.orange;
      advice = "Consider regular physical activity and a balanced diet. Consult your doctor.";
    } else {
      cat = "Obese"; col = const Color(0xFFE53935);
      advice = "Please consult a healthcare provider for a personalized weight management plan.";
    }

    setState(() { _bmi = bmi; _category = cat; _color = col; _advice = advice; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(title: const Text("BMI Calculator")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Column(
                children: [
                  const Text("Calculate Your BMI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0D2137))),
                  const SizedBox(height: 6),
                  const Text("Body Mass Index helps assess healthy weight range", style: TextStyle(fontSize: 12, color: Color(0xFF6B8EA8)), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: _field(_heightCtrl, "Height (cm)", "170")),
                    const SizedBox(width: 14),
                    Expanded(child: _field(_weightCtrl, "Weight (kg)", "70")),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _calculate, child: const Text("Calculate BMI"))),
                ],
              ),
            ),

            if (_bmi != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: Column(
                  children: [
                    // BMI Circle
                    Container(
                      width: 140, height: 140,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          border: Border.all(color: _color, width: 6),
                          color: _color.withOpacity(0.05)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(_bmi!.toStringAsFixed(1), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _color)),
                        Text("BMI", style: TextStyle(fontSize: 14, color: _color.withOpacity(0.7), fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Text(_category, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _color)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: _color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                      child: Text(_advice, style: TextStyle(fontSize: 13, color: _color, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 20),
                    // Scale
                    _bmiScale(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bmiScale() {
    return Column(
      children: [
        const Text("BMI Scale", style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D2137))),
        const SizedBox(height: 12),
        ...const [
          ["< 18.5", "Underweight", Colors.blue],
          ["18.5 – 24.9", "Normal", Color(0xFF2E7D32)],
          ["25 – 29.9", "Overweight", Colors.orange],
          ["≥ 30", "Obese", Color(0xFFE53935)],
        ].map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: row[2] as Color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            SizedBox(width: 100, child: Text(row[0] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            Text(row[1] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF6B8EA8))),
          ]),
        )),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D2137))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            filled: true, fillColor: const Color(0xFFF4F8FB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDE8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDE8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A6B9A), width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}