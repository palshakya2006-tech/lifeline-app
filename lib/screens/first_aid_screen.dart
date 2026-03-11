import 'package:flutter/material.dart';

class FirstAidScreen extends StatelessWidget {
  const FirstAidScreen({super.key});

  static const _guides = [
    {
      "emoji": "🫀",
      "title": "CPR",
      "color": 0xFFE53935,
      "steps": [
        "Call 108 immediately",
        "Place heel of hand on center of chest",
        "Push hard & fast — 100-120 compressions/min",
        "Allow chest to fully recoil between compressions",
        "Give 2 rescue breaths after every 30 compressions",
        "Continue until help arrives",
      ]
    },
    {
      "emoji": "🩸",
      "title": "Heavy Bleeding",
      "color": 0xFFAD1457,
      "steps": [
        "Apply firm pressure with clean cloth",
        "Do NOT remove cloth if soaked — add more",
        "Elevate injured area above heart level",
        "Apply pressure for at least 15 minutes",
        "Seek emergency care immediately",
      ]
    },
    {
      "emoji": "🔥",
      "title": "Burns",
      "color": 0xFFBF360C,
      "steps": [
        "Cool burn with cool (not cold) running water for 20 min",
        "Do NOT use ice, butter, or toothpaste",
        "Remove jewelry near burn area",
        "Cover loosely with cling film or clean bag",
        "Do NOT burst blisters",
        "Seek medical help for large/severe burns",
      ]
    },
    {
      "emoji": "😮",
      "title": "Choking",
      "color": 0xFF6A1B9A,
      "steps": [
        "Encourage coughing if person can cough",
        "Give 5 sharp back blows between shoulder blades",
        "Give 5 abdominal thrusts (Heimlich maneuver)",
        "Alternate back blows and abdominal thrusts",
        "Call 108 if object not dislodged",
      ]
    },
    {
      "emoji": "⚡",
      "title": "Seizure",
      "color": 0xFF1565C0,
      "steps": [
        "Stay calm — do NOT restrain the person",
        "Clear area of sharp/hard objects",
        "Gently place person on side (recovery position)",
        "Cushion their head",
        "Do NOT put anything in their mouth",
        "Call 108 if seizure lasts more than 5 minutes",
      ]
    },
    {
      "emoji": "🐍",
      "title": "Snake Bite",
      "color": 0xFF2E7D32,
      "steps": [
        "Keep person still and calm",
        "Keep bitten limb below heart level",
        "Remove watches/rings near bite site",
        "Do NOT suck venom, cut wound, or apply tourniquet",
        "Note snake's appearance if safe to do so",
        "Rush to nearest hospital IMMEDIATELY",
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(title: const Text("First Aid Guide")),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Text("🚨", style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "In life-threatening emergencies, always call 108 first!",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE53935)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _guides.length,
              itemBuilder: (ctx, i) => _GuideCard(guide: _guides[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatefulWidget {
  final Map<String, dynamic> guide;
  const _GuideCard({required this.guide});
  @override
  State<_GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<_GuideCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.guide["color"] as int);
    final steps = widget.guide["steps"] as List;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withOpacity(0.9), color]),
                borderRadius: _expanded
                    ? const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
                    : BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(widget.guide["emoji"] as String, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(widget.guide["title"] as String,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                  Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text("${e.key + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(e.value as String, style: const TextStyle(fontSize: 13, color: Color(0xFF0D2137), height: 1.4))),
                    ],
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}