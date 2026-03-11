import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});
  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _addRecord() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRecordSheet(uid: uid!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text("Medical History"),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFF1A6B9A),
          labelColor: const Color(0xFF1A6B9A),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: "Records"),
            Tab(text: "Medications"),
            Tab(text: "Vitals"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecord,
        backgroundColor: const Color(0xFF1A6B9A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Record", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _RecordsTab(uid: uid!),
          _MedicationsTab(uid: uid!),
          _VitalsTab(uid: uid!),
        ],
      ),
    );
  }
}

// ── RECORDS TAB ──────────────────────────────────────────────────────────────
class _RecordsTab extends StatelessWidget {
  final String uid;
  const _RecordsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users").doc(uid).collection("medical_history")
          .orderBy("date", descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _emptyState("No medical records yet", "Tap + to add your first record", "📋");
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snap.data!.docs.length,
          itemBuilder: (ctx, i) {
            final doc = snap.data!.docs[i];
            final d = doc.data() as Map<String, dynamic>;
            return _RecordCard(data: d, docId: doc.id, uid: uid);
          },
        );
      },
    );
  }
}

class _RecordCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final String uid;
  const _RecordCard({required this.data, required this.docId, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1A6B9A), Color(0xFF2E9CCA)]),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.medical_information, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(data["diagnosis"] ?? "Diagnosis", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
                Text(data["date"] ?? "", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await FirebaseFirestore.instance
                        .collection("users").doc(uid)
                        .collection("medical_history").doc(docId).delete();
                  },
                  child: const Icon(Icons.delete_outline, color: Colors.white70, size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _row("🏥 Hospital", data["hospital"] ?? "N/A"),
                _row("👨‍⚕️ Doctor", data["doctor"] ?? "N/A"),
                _row("💊 Treatment", data["treatment"] ?? "N/A"),
                if ((data["notes"] ?? "").isNotEmpty) _row("📝 Notes", data["notes"]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B8EA8)))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0D2137)))),
        ],
      ),
    );
  }
}

// ── MEDICATIONS TAB ──────────────────────────────────────────────────────────
class _MedicationsTab extends StatelessWidget {
  final String uid;
  const _MedicationsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users").doc(uid).collection("medications")
          .orderBy("added_at", descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _emptyState("No medications added", "Track your daily medications here", "💊");
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snap.data!.docs.length,
          itemBuilder: (ctx, i) {
            final doc = snap.data!.docs[i];
            final d = doc.data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medication, color: Colors.green, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d["name"] ?? "", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0D2137))),
                        Text("${d["dosage"] ?? ""} • ${d["frequency"] ?? ""}", style: const TextStyle(fontSize: 12, color: Color(0xFF6B8EA8))),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => FirebaseFirestore.instance.collection("users").doc(uid).collection("medications").doc(doc.id).delete(),
                    child: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── VITALS TAB ───────────────────────────────────────────────────────────────
class _VitalsTab extends StatefulWidget {
  final String uid;
  const _VitalsTab({required this.uid});
  @override
  State<_VitalsTab> createState() => _VitalsTabState();
}

class _VitalsTabState extends State<_VitalsTab> {
  final _bpCtrl = TextEditingController();
  final _sugarCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _hrCtrl = TextEditingController();

  Future<void> _saveVitals() async {
    await FirebaseFirestore.instance
        .collection("users").doc(widget.uid).collection("vitals")
        .add({
      "bp": _bpCtrl.text.trim(),
      "sugar": _sugarCtrl.text.trim(),
      "weight": _weightCtrl.text.trim(),
      "heart_rate": _hrCtrl.text.trim(),
      "recorded_at": Timestamp.now(),
      "date": "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
    });
    _bpCtrl.clear(); _sugarCtrl.clear(); _weightCtrl.clear(); _hrCtrl.clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vitals saved ✓"), backgroundColor: Color(0xFF2E7D32)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Input card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Log Today's Vitals",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0D2137))),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _vitalField(_bpCtrl, "Blood Pressure", "120/80")),
                  const SizedBox(width: 12),
                  Expanded(child: _vitalField(_hrCtrl, "Heart Rate", "72 bpm")),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _vitalField(_sugarCtrl, "Sugar Level", "90 mg/dL")),
                  const SizedBox(width: 12),
                  Expanded(child: _vitalField(_weightCtrl, "Weight", "65 kg")),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveVitals,
                    child: const Text("Save Vitals"),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // History
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Previous Readings",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0D2137))),
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users").doc(widget.uid).collection("vitals")
                .orderBy("recorded_at", descending: true)
                .limit(10)
                .snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return _emptyState("No vitals logged", "Start tracking your health metrics", "📊");
              }
              return Column(
                children: snap.data!.docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _vitalChip("❤️", d["bp"] ?? "-"),
                        _vitalChip("🩸", d["sugar"] ?? "-"),
                        _vitalChip("⚖️", d["weight"] ?? "-"),
                        _vitalChip("💓", d["heart_rate"] ?? "-"),
                        Text(d["date"] ?? "", style: const TextStyle(fontSize: 10, color: Color(0xFF6B8EA8))),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _vitalField(TextEditingController ctrl, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B8EA8))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF4F8FB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDE8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDE8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A6B9A), width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _vitalChip(String emoji, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0D2137))),
      ],
    );
  }
}

// ── ADD RECORD SHEET ─────────────────────────────────────────────────────────
class _AddRecordSheet extends StatefulWidget {
  final String uid;
  const _AddRecordSheet({required this.uid});
  @override
  State<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<_AddRecordSheet> {
  final _diagCtrl = TextEditingController();
  final _docCtrl = TextEditingController();
  final _hospCtrl = TextEditingController();
  final _treatCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _medNameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  int _type = 0; // 0 = record, 1 = medication
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final dateStr = "${now.day}/${now.month}/${now.year}";

      if (_type == 0) {
        await FirebaseFirestore.instance
            .collection("users").doc(widget.uid).collection("medical_history")
            .add({
          "diagnosis": _diagCtrl.text.trim(),
          "doctor": _docCtrl.text.trim(),
          "hospital": _hospCtrl.text.trim(),
          "treatment": _treatCtrl.text.trim(),
          "notes": _notesCtrl.text.trim(),
          "date": dateStr,
          "created_at": Timestamp.now(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection("users").doc(widget.uid).collection("medications")
            .add({
          "name": _medNameCtrl.text.trim(),
          "dosage": _dosageCtrl.text.trim(),
          "frequency": _freqCtrl.text.trim(),
          "added_at": Timestamp.now(),
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Record saved ✓"), backgroundColor: Color(0xFF2E7D32)),
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save"), backgroundColor: Color(0xFFE53935)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text("Add Record", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0D2137))),
            const SizedBox(height: 16),

            // Type toggle
            Row(
              children: [
                _typeBtn(0, "📋 Medical Record"),
                const SizedBox(width: 10),
                _typeBtn(1, "💊 Medication"),
              ],
            ),

            const SizedBox(height: 20),

            if (_type == 0) ...[
              _sheetField(_diagCtrl, "Diagnosis / Condition"),
              const SizedBox(height: 12),
              _sheetField(_docCtrl, "Doctor Name"),
              const SizedBox(height: 12),
              _sheetField(_hospCtrl, "Hospital / Clinic"),
              const SizedBox(height: 12),
              _sheetField(_treatCtrl, "Treatment / Prescription"),
              const SizedBox(height: 12),
              _sheetField(_notesCtrl, "Additional Notes", maxLines: 3),
            ] else ...[
              _sheetField(_medNameCtrl, "Medicine Name"),
              const SizedBox(height: 12),
              _sheetField(_dosageCtrl, "Dosage (e.g. 500mg)"),
              const SizedBox(height: 12),
              _sheetField(_freqCtrl, "Frequency (e.g. Twice daily)"),
            ],

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Save Record"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn(int index, String label) {
    final active = _type == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1A6B9A) : const Color(0xFFF4F8FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? const Color(0xFF1A6B9A) : const Color(0xFFDDE8F0)),
          ),
          child: Center(
            child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF6B8EA8))),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6B8EA8), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF4F8FB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDE8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDE8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A6B9A), width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

Widget _emptyState(String title, String subtitle, String emoji) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0D2137))),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF6B8EA8)), textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}