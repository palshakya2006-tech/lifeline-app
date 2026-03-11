import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IMPORTANT: Add to pubspec.yaml:
//   qr_flutter: ^4.1.0
//   url_launcher: ^6.2.5
//
// HOW THE QR WORKS:
//   The QR encodes a URL like:
//     https://lifeline-61f28.web.app/health-card?uid=<uid>&token=<base64token>
//   When scanned, it opens a Firebase-hosted web page that decodes the token
//   and renders the patient's health card in a browser — readable by any
//   emergency responder without needing the app.
//
//   The token is a base64-encoded JSON of the patient's critical health data,
//   embedded directly in the URL so it works offline (no server lookup needed).
//   Keep it compact — QR codes degrade with >300 chars.
// ─────────────────────────────────────────────────────────────────────────────

class HealthWalletScreen extends StatefulWidget {
  const HealthWalletScreen({super.key});

  @override
  State<HealthWalletScreen> createState() => _HealthWalletScreenState();
}

class _HealthWalletScreenState extends State<HealthWalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic> _userData = {};
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _meds = [];
  List<Map<String, dynamic>> _vitals = [];
  bool _loading = true;
  String _qrUrl = "";

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection("users").doc(uid).get();
      if (userDoc.exists) {
        _userData = userDoc.data() as Map<String, dynamic>;
      }

      final recSnap = await FirebaseFirestore.instance
          .collection("users").doc(uid)
          .collection("medical_history")
          .orderBy("created_at", descending: true)
          .limit(5)
          .get();
      _records = recSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();

      final medSnap = await FirebaseFirestore.instance
          .collection("users").doc(uid)
          .collection("medications")
          .orderBy("added_at", descending: true)
          .limit(10)
          .get();
      _meds = medSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();

      final vitSnap = await FirebaseFirestore.instance
          .collection("users").doc(uid)
          .collection("vitals")
          .orderBy("recorded_at", descending: true)
          .limit(1)
          .get();
      _vitals = vitSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();

      _buildQRUrl(uid);
    } catch (e) {
      debugPrint("Error loading wallet data: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Builds a URL-based QR ────────────────────────────────────────────────
  // The QR encodes a URL. When scanned, a browser opens the LifeLine web
  // health card page, which reads the base64 token from the URL and renders
  // the patient data — no app install required for the responder.
  void _buildQRUrl(String uid) {
    final latestVital = _vitals.isNotEmpty ? _vitals.first : <String, dynamic>{};

    // Compact payload — only critical emergency fields (keep URL short)
    final payload = {
      "n": _userData["name"] ?? "",
      "g": _userData["gender"] ?? "",
      "b": _userData["blood_group"] ?? "",
      "e": _userData["emergency_contact"] ?? "",
      "a": _userData["allergies"] ?? "",
      "c": _userData["chronic_conditions"] ?? "",
      "h": _userData["height"] ?? "",
      "w": _userData["weight"] ?? "",
      if (latestVital.isNotEmpty) ...{
        "bp": latestVital["bp"] ?? "",
        "sg": latestVital["sugar"] ?? "",
        "hr": latestVital["heart_rate"] ?? "",
      },
      "rx": _meds.take(3).map((m) => m["name"] ?? "").join(", "),
      "dx": _records.take(2).map((r) => r["diagnosis"] ?? "").join(", "),
      "dt": DateTime.now().toIso8601String().substring(0, 10),
    };

    // Base64-encode the compact payload
    final token = base64Url.encode(utf8.encode(jsonEncode(payload)));

    // URL points to your Firebase-hosted health card viewer page.
    // Deploy the companion web page to Firebase Hosting at this path.
    // The web page reads ?t=<token>, decodes it, and renders the health card.
    _qrUrl = "https://lifeline-61f28.web.app/health-card?uid=$uid&t=$token";
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _qrUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Health card link copied"),
        backgroundColor: Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _refreshData() {
    setState(() => _loading = true);
    _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text("Health Wallet"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: "Refresh",
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFF1A6B9A),
          labelColor: const Color(0xFF1A6B9A),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_2, size: 20), text: "QR Card"),
            Tab(icon: Icon(Icons.folder_open, size: 20), text: "My Records"),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A6B9A)))
          : TabBarView(
        controller: _tabs,
        children: [
          _QRTab(
            qrUrl: _qrUrl,
            userData: _userData,
            onCopy: _copyLink,
          ),
          _DataTab(
            userData: _userData,
            records: _records,
            medications: _meds,
            vitals: _vitals,
          ),
        ],
      ),
    );
  }
}

// ── QR TAB ────────────────────────────────────────────────────────────────────
class _QRTab extends StatelessWidget {
  final String qrUrl;
  final Map<String, dynamic> userData;
  final VoidCallback onCopy;

  const _QRTab({
    required this.qrUrl,
    required this.userData,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final name = userData["name"] ?? "Patient";
    final blood = userData["blood_group"] ?? "Unknown";
    final allergies = userData["allergies"] ?? "";
    final conditions = userData["chronic_conditions"] ?? "";
    final emergency = userData["emergency_contact"] ?? "Not set";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Emergency banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.qr_code_scanner, color: Color(0xFFE53935), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "QR opens a web page with your health info — no app needed for responders",
                    style: TextStyle(fontSize: 12, color: Color(0xFFE53935), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Digital Health Card
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D2137), Color(0xFF1A6B9A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A6B9A).withOpacity(0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Card header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.medical_information, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("LIFELINE",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
                        Text("Digital Health Card",
                            style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.water_drop, color: Colors.red, size: 12),
                        const SizedBox(width: 4),
                        Text(blood,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                      ]),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // QR Code — encodes a URL, not raw JSON
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      qrUrl.isNotEmpty
                          ? QrImageView(
                        data: qrUrl,
                        version: QrVersions.auto,
                        size: 180,
                        backgroundColor: Colors.white,
                        // Eye-module color to match branding
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0D2137),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF1A6B9A),
                        ),
                        errorStateBuilder: (ctx, err) => const SizedBox(
                          width: 180,
                          height: 180,
                          child: Center(child: Text("QR Error", style: TextStyle(color: Colors.red))),
                        ),
                      )
                          : const SizedBox(
                        width: 180,
                        height: 180,
                        child: Center(child: Text("No data", style: TextStyle(color: Colors.grey))),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Scan to open health card in browser",
                        style: TextStyle(fontSize: 10, color: Color(0xFF6B8EA8)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone, color: Colors.white54, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      "Emergency: $emergency",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _infoPill("🩸 $blood", Colors.red),
                    if (allergies.isNotEmpty && allergies.toLowerCase() != "none")
                      _infoPill("⚠️ $allergies", Colors.orange),
                    if (conditions.isNotEmpty && conditions.toLowerCase() != "none")
                      _infoPill("🏥 $conditions", Colors.purple),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  "Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text("Copy Link"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF1A6B9A)),
                    foregroundColor: const Color(0xFF1A6B9A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showShareSheet(context),
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text("Share Card"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Note about web hosting
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A6B9A).withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1A6B9A).withOpacity(0.2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF1A6B9A), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Deploy the LifeLine web viewer to Firebase Hosting so responders can open this QR in any browser, even without the app.",
                    style: TextStyle(fontSize: 11, color: Color(0xFF1A6B9A)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text("Share Health Card",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0D2137))),
            const SizedBox(height: 6),
            const Text("Share your emergency health card link with trusted contacts",
                style: TextStyle(fontSize: 13, color: Color(0xFF6B8EA8)), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _shareBtn("📱 SMS", Colors.green, () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text("SMS sharing coming soon")));
              }),
              const SizedBox(width: 16),
              _shareBtn("📧 Email", Colors.blue, () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text("Email sharing coming soon")));
              }),
              const SizedBox(width: 16),
              _shareBtn("📋 Copy", Colors.purple, () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: "LifeLine Health Card — scan QR in app or share link"));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text("Copied!")));
              }),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _shareBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Text(label.split(" ")[0], style: const TextStyle(fontSize: 24)),
        ),
        const SizedBox(height: 6),
        Text(label.substring(label.indexOf(" ") + 1),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Widget _infoPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ── DATA TAB ──────────────────────────────────────────────────────────────────
class _DataTab extends StatelessWidget {
  final Map<String, dynamic> userData;
  final List<Map<String, dynamic>> records;
  final List<Map<String, dynamic>> medications;
  final List<Map<String, dynamic>> vitals;

  const _DataTab({
    required this.userData,
    required this.records,
    required this.medications,
    required this.vitals,
  });

  @override
  Widget build(BuildContext context) {
    final latestVital = vitals.isNotEmpty ? vitals.first : <String, dynamic>{};

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Patient Profile Summary Card ─────────────────────────────────
          _sectionHeader("👤 Patient Profile", const Color(0xFF1A6B9A)),
          const SizedBox(height: 10),
          Container(
            decoration: _cardDecor(),
            child: Column(
              children: [
                // Avatar row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D2137), Color(0xFF1A6B9A)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          (userData["name"] ?? "?").isNotEmpty
                              ? (userData["name"] as String)[0].toUpperCase()
                              : "?",
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData["name"] ?? "—",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userData["email"] ?? "",
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      // Blood group badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: Text(
                          "🩸 ${userData["blood_group"] ?? "?"}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                // Info grid
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(children: [
                        _infoTile(Icons.person, "Gender", userData["gender"] ?? "—", const Color(0xFF1A6B9A)),
                        const SizedBox(width: 10),
                        _infoTile(Icons.height, "Height",
                            userData["height"]?.toString().isNotEmpty == true
                                ? "${userData["height"]} cm"
                                : "—",
                            const Color(0xFF2E7D32)),
                        const SizedBox(width: 10),
                        _infoTile(Icons.monitor_weight_outlined, "Weight",
                            userData["weight"]?.toString().isNotEmpty == true
                                ? "${userData["weight"]} kg"
                                : "—",
                            const Color(0xFF6A1B9A)),
                      ]),
                      const SizedBox(height: 14),
                      if ((userData["allergies"] ?? "").toString().isNotEmpty &&
                          userData["allergies"] != "None")
                        _alertRow(
                          Icons.warning_amber_rounded,
                          "Allergies",
                          userData["allergies"],
                          Colors.orange,
                        ),
                      if ((userData["chronic_conditions"] ?? "").toString().isNotEmpty &&
                          userData["chronic_conditions"] != "None")
                        _alertRow(
                          Icons.medical_information,
                          "Chronic Conditions",
                          userData["chronic_conditions"],
                          Colors.purple,
                        ),
                      _alertRow(
                        Icons.phone,
                        "Emergency Contact",
                        userData["emergency_contact"] ?? "Not set",
                        const Color(0xFFE53935),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Latest Vitals ─────────────────────────────────────────────────
          _sectionHeader("📊 Latest Vitals", const Color(0xFF2E7D32)),
          const SizedBox(height: 10),
          latestVital.isNotEmpty
              ? Container(
            decoration: _cardDecor(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(children: [
                  _vitalChip("💓", "BP", latestVital["bp"] ?? "—", Colors.red),
                  const SizedBox(width: 10),
                  _vitalChip("🩸", "Sugar", "${latestVital["sugar"] ?? "—"} mg/dL", Colors.orange),
                  const SizedBox(width: 10),
                  _vitalChip("🫀", "Heart Rate", "${latestVital["heart_rate"] ?? "—"} bpm", const Color(0xFF1A6B9A)),
                ]),
                if (latestVital["date"] != null) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.calendar_today, size: 13, color: Color(0xFF6B8EA8)),
                    const SizedBox(width: 6),
                    Text("Recorded: ${latestVital["date"]}",
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B8EA8))),
                  ]),
                ],
              ],
            ),
          )
              : _emptyCard("No vitals recorded yet", Icons.monitor_heart_outlined),

          const SizedBox(height: 24),

          // ── Current Medications ───────────────────────────────────────────
          _sectionHeader("💊 Medications (${medications.length})", const Color(0xFF6A1B9A)),
          const SizedBox(height: 10),
          medications.isEmpty
              ? _emptyCard("No medications added", Icons.medication_outlined)
              : Column(
            children: medications.asMap().entries.map((e) {
              final m = e.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: _cardDecor(),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text("💊", style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m["name"] ?? "—",
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF0D2137)),
                          ),
                          if ((m["dosage"] ?? "").isNotEmpty ||
                              (m["frequency"] ?? "").isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              [m["dosage"], m["frequency"]]
                                  .where((s) => s != null && s.isNotEmpty)
                                  .join(" · "),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B8EA8)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "#${e.key + 1}",
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6A1B9A),
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // ── Medical Records ───────────────────────────────────────────────
          _sectionHeader("📋 Medical Records (${records.length})", const Color(0xFFBF360C)),
          const SizedBox(height: 10),
          records.isEmpty
              ? _emptyCard("No medical records yet", Icons.folder_open_outlined)
              : Column(
            children: records.map((r) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: _cardDecor(),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBF360C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.medical_information,
                          color: Color(0xFFBF360C), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r["diagnosis"] ?? "—",
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF0D2137)),
                          ),
                          const SizedBox(height: 4),
                          if ((r["doctor"] ?? "").isNotEmpty)
                            Row(children: [
                              const Icon(Icons.local_hospital_outlined,
                                  size: 12, color: Color(0xFF6B8EA8)),
                              const SizedBox(width: 4),
                              Text(r["doctor"],
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF6B8EA8))),
                            ]),
                          if ((r["notes"] ?? "").isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(r["notes"],
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF0D2137)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBF360C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            r["date"] ?? "",
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFBF360C),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 3))
    ],
  );

  Widget _sectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13, color: color),
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF6B8EA8)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _alertRow(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ),
          Expanded(
            child: Text(value ?? "—",
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D2137))),
          ),
        ],
      ),
    );
  }

  Widget _vitalChip(String emoji, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 12, color: color),
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF6B8EA8))),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B8EA8))),
        ],
      ),
    );
  }
}