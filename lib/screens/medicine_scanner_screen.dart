import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MedicineScannerScreen extends StatefulWidget {
  const MedicineScannerScreen({super.key});

  @override
  State<MedicineScannerScreen> createState() =>
      _MedicineScannerScreenState();
}

class _MedicineScannerScreenState
    extends State<MedicineScannerScreen> {

  final TextEditingController medicineController =
  TextEditingController();

  List<dynamic> medicineDatabase = [];
  List<dynamic> suggestions = [];
  String result = "";

  @override
  void initState() {
    super.initState();
    loadDatabase();
  }

  // ✅ LOAD JSON
  Future<void> loadDatabase() async {
    final String response =
    await rootBundle.loadString(
        'assets/indian_medicine_data.json');

    final data = json.decode(response);

    setState(() {
      medicineDatabase = data;
    });
  }

  // ✅ LIVE SUGGESTIONS
  void getSuggestions(String query) {
    if (query.isEmpty) {
      setState(() => suggestions.clear());
      return;
    }

    final matches = medicineDatabase
        .where((item) =>
        item["name"]
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();

    setState(() {
      suggestions = matches.take(8).toList();
    });
  }

  // ✅ MEDICAL GUIDANCE
  Map<String, String> getMedicalGuidance(
      String composition) {

    composition = composition.toLowerCase();

    if (composition.contains("amoxycillin") ||
        composition.contains("clavulanic")) {
      return {
        "disease":
        "Bacterial infections (throat, chest, sinus)",
        "symptoms":
        "Fever, throat pain, infection-related swelling",
        "timing":
        "Take after food to avoid stomach upset."
      };
    }

    if (composition.contains("ibuprofen") ||
        composition.contains("aceclofenac")) {
      return {
        "disease": "Pain & inflammation",
        "symptoms":
        "Headache, body pain, joint pain",
        "timing":
        "Take after meals with water."
      };
    }

    if (composition.contains("pantoprazole") ||
        composition.contains("omeprazole")) {
      return {
        "disease":
        "Acidity / Gastric issues",
        "symptoms":
        "Burning sensation, acid reflux",
        "timing":
        "Take 30 minutes before breakfast."
      };
    }

    if (composition.contains("metformin")) {
      return {
        "disease": "Type 2 Diabetes",
        "symptoms":
        "High blood sugar, fatigue",
        "timing":
        "Take after food."
      };
    }

    return {
      "disease":
      "Various medical conditions",
      "symptoms":
      "Depends on doctor's diagnosis",
      "timing":
      "Take only as prescribed."
    };
  }

  // ✅ SEARCH FUNCTION
  void searchMedicine(String name) {

    final medicine = medicineDatabase
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (item) => item["name"]
          .toString()
          .toLowerCase()
          .contains(name.toLowerCase()),
      orElse: () => {},
    );

    if (medicine.isEmpty) {
      setState(() {
        result = "Medicine not found.";
        suggestions.clear();
      });
      return;
    }

    String composition =
        "${medicine["short_composition1"] ?? ""} "
        "${medicine["short_composition2"] ?? ""}";

    Map<String, String> guidance =
    getMedicalGuidance(composition);

    setState(() {
      result = """
💊 ${medicine["name"]}

🏢 Manufacturer:
${medicine["manufacturer_name"] ?? "N/A"}

💰 Price:
₹ ${medicine["price(₹)"] ?? medicine["price"] ?? "N/A"}

📦 Pack Size:
${medicine["pack_size_label"] ?? "N/A"}

🧪 Composition:
$composition

🦠 Used For:
${guidance["disease"]}

🤒 Common Symptoms:
${guidance["symptoms"]}

⏰ When To Take:
${guidance["timing"]}
""";

      suggestions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {

    bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Medicine Scanner"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // 🔍 SEARCH BAR
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: medicineController,
                    onChanged: getSuggestions,
                    decoration: const InputDecoration(
                      labelText:
                      "Enter Medicine Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (medicineController
                        .text.isNotEmpty) {
                      searchMedicine(
                          medicineController.text
                              .trim());
                    }
                  },
                  child: const Text("Search"),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 🔽 SUGGESTIONS
            ...suggestions.map((item) =>
                ListTile(
                  leading: const Icon(
                      Icons.medication),
                  title: Text(item["name"]),
                  onTap: () {
                    medicineController.text =
                    item["name"];
                    searchMedicine(
                        item["name"]);
                  },
                )),

            const SizedBox(height: 15),

            // 📋 RESULT CARD
            if (result.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                          const Color(0xFF1B3B5A),
                          const Color(0xFF244E75),
                        ]
                            : [
                          const Color(0xFF6C99C6),
                          const Color(0xFF4F7EA8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      result,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}