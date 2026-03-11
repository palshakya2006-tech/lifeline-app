import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});
  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _ringCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _ringAnim;
  bool _sosActive = false;
  String _emergencyContact = "";

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _ringAnim = Tween<double>(begin: 1.0, end: 1.4)
        .animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));
    _loadContact();
  }

  Future<void> _loadContact() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _emergencyContact = (doc.data() as Map<String, dynamic>)["emergency_contact"] ?? "";
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  Future<bool> _getPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return false;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm != LocationPermission.denied && perm != LocationPermission.deniedForever;
  }

  Future<void> activateSOS() async {
    setState(() => _sosActive = true);

    String message;
    try {
      final hasPerm = await _getPermission();
      if (hasPerm) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        message = "🚨 EMERGENCY ALERT 🚨\nI need immediate help!\nLocation: https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
      } else {
        message = "🚨 EMERGENCY ALERT 🚨\nI need immediate help! Please contact me immediately.";
      }
    } catch (_) {
      message = "🚨 EMERGENCY ALERT 🚨\nI need immediate help! Please contact me immediately.";
    }

    // SMS to emergency contact
    if (_emergencyContact.isNotEmpty) {
      final smsUri = Uri.parse("sms:$_emergencyContact?body=${Uri.encodeComponent(message)}");
      await launchUrl(smsUri, mode: LaunchMode.externalApplication);
    }

    await Future.delayed(const Duration(seconds: 1));

    // Call 108
    await launchUrl(Uri.parse("tel:108"), mode: LaunchMode.externalApplication);

    if (mounted) setState(() => _sosActive = false);
  }

  Future<void> _callNumber(String number) async {
    await launchUrl(Uri.parse("tel:$number"), mode: LaunchMode.externalApplication);
  }

  Future<void> _openHospitals() async {
    await launchUrl(Uri.parse("geo:0,0?q=hospitals+near+me"), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.emergency, color: Colors.red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Emergency Mode", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                      Text("Tap SOS to alert emergency contacts", style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // SOS Button with rings
            Center(
              child: GestureDetector(
                onTap: activateSOS,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    AnimatedBuilder(
                      animation: _ringAnim,
                      builder: (_, __) => Container(
                        width: 200 * _ringAnim.value,
                        height: 200 * _ringAnim.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.red.withOpacity(0.15 * (2 - _ringAnim.value)),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // Inner ring
                    AnimatedBuilder(
                      animation: _ringAnim,
                      builder: (_, __) => Container(
                        width: 170 * (_ringAnim.value * 0.9),
                        height: 170 * (_ringAnim.value * 0.9),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withOpacity(0.08 * (2 - _ringAnim.value)),
                        ),
                      ),
                    ),
                    // Main button
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        width: 150, height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFFFF5252), Color(0xFFB71C1C)],
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.red.withOpacity(0.6), blurRadius: 30, spreadRadius: 5),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("🚨", style: TextStyle(fontSize: 36)),
                            const SizedBox(height: 4),
                            Text(
                              _sosActive ? "SENDING..." : "S O S",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              _emergencyContact.isNotEmpty
                  ? "Will SMS $_emergencyContact + call 108"
                  : "Will call 108 • Set emergency contact in Profile",
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text("QUICK CALL", style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _quickBtn("🚑 Ambulance", "108", Colors.red, () => _callNumber("108"))),
                    const SizedBox(width: 10),
                    Expanded(child: _quickBtn("🚒 Fire", "101", Colors.orange, () => _callNumber("101"))),
                    const SizedBox(width: 10),
                    Expanded(child: _quickBtn("👮 Police", "100", Colors.blue, () => _callNumber("100"))),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openHospitals,
                      icon: const Icon(Icons.local_hospital, color: Colors.white70),
                      label: const Text("Find Nearby Hospitals", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickBtn(String label, String number, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label.split(" ")[0], style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(label.substring(label.indexOf(" ") + 1),
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
            Text(number, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}