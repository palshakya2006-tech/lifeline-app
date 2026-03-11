import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {

  static const hfToken = "YOUR_API_KEY";

  static Future<String> analyzeHealth({
    required int age,
    required int bp,
    required int sugar,
  }) async {

    final url = Uri.parse(
        "https://router.huggingface.co/hf-inference/models/HuggingFaceH4/zephyr-7b-beta"
    );

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "inputs":
          "User: Analyze health risk for Age $age, Blood Pressure $bp, Sugar $sugar. Give short medical advice.\nAssistant:"
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data[0]["generated_text"];
      } else {
        return "HF Error: ${response.statusCode}\n${response.body}";
      }
    } catch (e) {
      return "Network Error: $e";
    }
  }
}