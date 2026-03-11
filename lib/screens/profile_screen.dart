import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; // for themeNotifier
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String gender;
  const ProfileScreen({super.key, required this.gender});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl       = TextEditingController();
  final _emergCtrl      = TextEditingController();
  final _heightCtrl     = TextEditingController();
  final _weightCtrl     = TextEditingController();
  final _allergiesCtrl  = TextEditingController();
  final _chronicCtrl    = TextEditingController();
  String _gender     = "Male";
  String _bloodGroup = "Unknown";
  bool _loading = true;
  bool _saving  = false;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _gender = widget.gender;
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emergCtrl.dispose(); _heightCtrl.dispose();
    _weightCtrl.dispose(); _allergiesCtrl.dispose(); _chronicCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
      if (!mounted) return;
      if (doc.exists) {
        final d = doc.data() as Map<String, dynamic>;
        _nameCtrl.text      = d["name"] ?? "";
        _emergCtrl.text     = d["emergency_contact"] ?? "";
        _heightCtrl.text    = d["height"] ?? "";
        _weightCtrl.text    = d["weight"] ?? "";
        _allergiesCtrl.text = d["allergies"] ?? "";
        _chronicCtrl.text   = d["chronic_conditions"] ?? "";
        _gender             = d["gender"] ?? "Male";
        _bloodGroup         = d["blood_group"] ?? "Unknown";
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "name":               _nameCtrl.text.trim(),
        "gender":             _gender,
        "blood_group":        _bloodGroup,
        "emergency_contact":  _emergCtrl.text.trim(),
        "height":             _heightCtrl.text.trim(),
        "weight":             _weightCtrl.text.trim(),
        "allergies":          _allergiesCtrl.text.trim(),
        "chronic_conditions": _chronicCtrl.text.trim(),
        "email":              FirebaseAuth.instance.currentUser!.email ?? "",
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Profile updated ✓"),
        backgroundColor: Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Failed to update profile"),
        backgroundColor: Color(0xFFE53935),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email   = FirebaseAuth.instance.currentUser?.email ?? "";
    final initial = _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : "U";
    final cardBg  = _isDark ? const Color(0xFF141D2E) : Colors.white;
    final surfBg  = _isDark ? const Color(0xFF1A2540) : const Color(0xFFF4F8FB);
    final border  = _isDark ? const Color(0xFF2A3A55) : const Color(0xFFDDE8F0);
    final textPri = _isDark ? Colors.white : const Color(0xFF0D2137);
    final textSec = _isDark ? const Color(0xFF7B9BB8) : const Color(0xFF6B8EA8);

    return Scaffold(
      backgroundColor: _isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF4F8FB),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A6B9A)))
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  height: 200,
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
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("My Profile",
                            style: TextStyle(
                                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        Row(
                          children: [
                            // ── Dark Mode Toggle ──────────────────────
                            GestureDetector(
                              onTap: () => themeNotifier.toggle(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isDark ? Icons.light_mode : Icons.dark_mode,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isDark ? "Light" : "Dark",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout, color: Colors.white70),
                              tooltip: "Sign Out",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        // Logo + Avatar stacked
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: const Color(0xFF1A6B9A),
                                child: Text(initial,
                                    style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(email,
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── App Settings Card ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: _isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("App Settings",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPri)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF1A6B9A).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Icon(
                                    _isDark ? Icons.dark_mode : Icons.light_mode,
                                    color: const Color(0xFF1A6B9A), size: 18),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Dark Mode",
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPri)),
                                  Text(_isDark ? "Currently: Dark" : "Currently: Light",
                                      style: TextStyle(fontSize: 11, color: textSec)),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: _isDark,
                            onChanged: (_) => themeNotifier.toggle(),
                            activeColor: const Color(0xFF1A6B9A),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _section("Personal Info", cardBg, textPri, textSec, surfBg, border, [
                  _field("Full Name", _nameCtrl, Icons.person_outline, surfBg, border, textPri, textSec),
                  const SizedBox(height: 14),
                  _field("Emergency Contact", _emergCtrl, Icons.phone_outlined, surfBg, border, textPri, textSec, type: TextInputType.phone),
                  const SizedBox(height: 14),
                  _dropdown("Gender", _gender, ["Male", "Female", "Other"],
                          (v) => setState(() => _gender = v!), surfBg, border, textPri, textSec),
                ]),

                const SizedBox(height: 20),

                _section("Medical Info", cardBg, textPri, textSec, surfBg, border, [
                  _dropdown("Blood Group", _bloodGroup,
                      ["Unknown", "A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"],
                          (v) => setState(() => _bloodGroup = v!), surfBg, border, textPri, textSec),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _field("Height (cm)", _heightCtrl, Icons.height, surfBg, border, textPri, textSec, type: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _field("Weight (kg)", _weightCtrl, Icons.monitor_weight_outlined, surfBg, border, textPri, textSec, type: TextInputType.number)),
                  ]),
                  const SizedBox(height: 14),
                  _field("Allergies", _allergiesCtrl, Icons.warning_amber_outlined, surfBg, border, textPri, textSec),
                  const SizedBox(height: 14),
                  _field("Chronic Conditions", _chronicCtrl, Icons.medical_information_outlined, surfBg, border, textPri, textSec),
                ]),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Save Changes"),
                  ),
                ),

                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Color cardBg, Color textPri, Color textSec,
      Color surfBg, Color border, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.04),
            blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPri)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      Color surfBg, Color border, Color textPri, Color textSec,
      {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSec)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          style: TextStyle(color: textPri),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: textSec),
            filled: true,
            fillColor: surfBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1A6B9A), width: 2)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged,
      Color surfBg, Color border, Color textPri, Color textSec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSec)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: surfBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: surfBg,
            style: TextStyle(fontSize: 14, color: textPri),
            items: items
                .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: TextStyle(fontSize: 14, color: textPri))))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
