import 'package:flutter/material.dart';
import 'dart:math';

class RiskPredictorScreen extends StatefulWidget {
  const RiskPredictorScreen({super.key});

  @override
  State<RiskPredictorScreen> createState() =>
      _RiskPredictorScreenState();
}

class _RiskPredictorScreenState
    extends State<RiskPredictorScreen> {

  final ageController = TextEditingController();
  final bpController = TextEditingController();
  final sugarController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  double riskPercentage = 0;
  String resultText = "";
  String recommendationText = "";
  String bmiText = "";
  String diseaseText = "";
  Color resultColor = Colors.green;

  bool isValid = false;

  @override
  void initState() {
    super.initState();
    ageController.addListener(validateInputs);
    bpController.addListener(validateInputs);
    sugarController.addListener(validateInputs);
    weightController.addListener(validateInputs);
    heightController.addListener(validateInputs);
  }

  void validateInputs() {
    setState(() {
      isValid =
          ageController.text.isNotEmpty &&
              bpController.text.contains(".") &&
              sugarController.text.isNotEmpty &&
              weightController.text.isNotEmpty &&
              heightController.text.isNotEmpty;
    });
  }

  void predictRisk() {

    int age = int.parse(ageController.text);
    double sugar = double.parse(sugarController.text);
    double weight = double.parse(weightController.text);
    double heightCm = double.parse(heightController.text);

    List<String> bpParts = bpController.text.split(".");
    int systolic = int.parse(bpParts[0]);
    int diastolic = int.parse(bpParts[1]);

    double heightM = heightCm / 100;
    double bmi = weight / pow(heightM, 2);

    int score = 0;

    if (age > 50) score += 2;
    if (systolic > 140 || diastolic > 90) score += 3;
    if (sugar > 150) score += 3;
    if (bmi >= 30) score += 2;

    double percentage = (score / 10) * 100;

    setState(() {
      riskPercentage = percentage / 100;
      bmiText = "BMI: ${bmi.toStringAsFixed(1)}";

      if (percentage >= 60) {
        resultText = "High Risk";
        resultColor = Colors.red;
        recommendationText =
        "Immediate medical consultation recommended.";

        diseaseText =
        "Possible Conditions:\n• Hypertension\n• Type 2 Diabetes\n• Obesity-related heart disease\n• Cardiovascular risk";

      } else if (percentage >= 30) {
        resultText = "Moderate Risk";
        resultColor = Colors.orange;
        recommendationText =
        "Monitor health regularly and consult a doctor.";

        diseaseText =
        "Possible Conditions:\n• Pre-diabetes\n• Elevated blood pressure\n• Metabolic syndrome";

      } else {
        resultText = "Low Risk";
        resultColor = Colors.green;
        recommendationText =
        "Maintain healthy lifestyle and regular checkups.";

        diseaseText =
        "No major risk indicators detected.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Risk Predictor"),
      ),

      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F2A45), const Color(0xFF0B1F33)]
                : [const Color(0xFFEAF3FB), const Color(0xFFD6E8F7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SingleChildScrollView(
          child: Column(
            children: [

              _inputCard("Age", ageController),
              _inputCard("Blood Pressure (120.80)", bpController),
              _inputCard("Sugar Level", sugarController),
              _inputCard("Weight (kg)", weightController),
              _inputCard("Height (cm)", heightController),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isValid ? predictRisk : null,
                  style: ElevatedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Analyze Risk",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              if (resultText.isNotEmpty) _resultSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputCard(String label,
      TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C99C6), Color(0xFF4F7EA8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [

          Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            // ADD THIS LINE:
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              // Optional: Add hintStyle if you use hints to ensure they are visible
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _resultSection() {
    return Column(
      children: [

        SizedBox(
          height: 140,
          width: 140,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: riskPercentage,
                strokeWidth: 12,
                color: resultColor,
                backgroundColor: Colors.grey.shade300,
              ),
              Center(
                child: Text(
                  "${(riskPercentage * 100).toInt()}%",
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          resultText,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: resultColor),
        ),

        const SizedBox(height: 10),

        Text(bmiText,
            style: const TextStyle(fontSize: 16)),

        const SizedBox(height: 10),

        Text(
          recommendationText,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 15),

        Text(
          diseaseText,
          textAlign: TextAlign.left,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  @override
  void dispose() {
    ageController.dispose();
    bpController.dispose();
    sugarController.dispose();
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }
}