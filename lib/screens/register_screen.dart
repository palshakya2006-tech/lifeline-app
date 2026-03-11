import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _gender = "Male";
  String _bloodGroup = "Unknown";
  bool _isLoading = false;
  bool _obscurePass = true;
  int _step = 0; // 0 = personal, 1 = medical

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose();
    _confirmCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty || _phoneCtrl.text.trim().isEmpty) {
      _snack("Please fill all fields", isError: true); return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      _snack("Passwords do not match", isError: true); return;
    }
    if (_passCtrl.text.length < 6) {
      _snack("Password must be at least 6 characters", isError: true); return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      await cred.user!.updateDisplayName(_nameCtrl.text.trim());

      await FirebaseFirestore.instance.collection("users").doc(cred.user!.uid).set({
        "name": _nameCtrl.text.trim(),
        "email": _emailCtrl.text.trim(),
        "gender": _gender,
        "blood_group": _bloodGroup,
        "emergency_contact": _phoneCtrl.text.trim(),
        "allergies": "",
        "chronic_conditions": "",
        "height": "",
        "weight": "",
        "created_at": Timestamp.now(),
        "medical_history": [],
      });

      await cred.user!.sendEmailVerification();

      if (!mounted) return;
      _snack("Account created! Please verify your email.", isError: false);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = "Registration failed";
      if (e.code == 'email-already-in-use') msg = "Email already registered";
      if (e.code == 'weak-password') msg = "Password too weak";
      if (e.code == 'invalid-email') msg = "Invalid email address";
      _snack(msg, isError: true);
    } catch (e) {
      if (!mounted) return;
      _snack("Registration failed. Try again.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D2137), Color(0xFF1A6B9A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + Title
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text("Create Account", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),

                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    "Join LifeLine — your personal health companion",
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13),
                  ),
                ),

                const SizedBox(height: 28),

                // Step indicator
                Row(
                  children: [
                    _stepDot(0, "Personal"),
                    Expanded(child: Container(height: 2, color: _step >= 1 ? Colors.white : Colors.white24)),
                    _stepDot(1, "Medical"),
                  ],
                ),

                const SizedBox(height: 28),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: _step == 0 ? _personalStep() : _medicalStep(),
                ),

                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Already have an account? Sign In",
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepDot(int index, String label) {
    final active = _step >= index;
    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white24,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text("${index + 1}",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: active ? const Color(0xFF1A6B9A) : Colors.white54,
                )),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _personalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label("Full Name"),
        const SizedBox(height: 8),
        _field(_nameCtrl, "John Doe", Icons.person_outline),
        const SizedBox(height: 16),
        _label("Email Address"),
        const SizedBox(height: 8),
        _field(_emailCtrl, "your@email.com", Icons.email_outlined,
            type: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _label("Password"),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscurePass,
          decoration: _decor("••••••••", Icons.lock_outline).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF6B8EA8)),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _label("Confirm Password"),
        const SizedBox(height: 8),
        _field(_confirmCtrl, "••••••••", Icons.lock_outline, obscure: true),
        const SizedBox(height: 16),
        _label("Emergency Contact"),
        const SizedBox(height: 8),
        _field(_phoneCtrl, "+91 XXXXXXXXXX", Icons.phone_outlined,
            type: TextInputType.phone),
        const SizedBox(height: 16),
        _label("Gender"),
        const SizedBox(height: 8),
        _dropdown(
          value: _gender,
          items: ["Male", "Female", "Other"],
          onChanged: (v) => setState(() => _gender = v!),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty ||
                  _passCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
                _snack("Please fill all fields", isError: true);
                return;
              }
              setState(() => _step = 1);
            },
            child: const Text("Next: Medical Info →"),
          ),
        ),
      ],
    );
  }

  Widget _medicalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Medical Information",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0D2137)),
        ),
        const SizedBox(height: 4),
        Text("This helps LifeLine give personalized health insights",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 20),
        _label("Blood Group"),
        const SizedBox(height: 8),
        _dropdown(
          value: _bloodGroup,
          items: ["Unknown", "A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"],
          onChanged: (v) => setState(() => _bloodGroup = v!),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _step = 0),
              icon: const Icon(Icons.arrow_back_ios_new, size: 14),
              label: const Text("Back"),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF1A6B9A)),
            ),
            const Spacer(),
            SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: _isLoading ? null : register,
                child: _isLoading
                    ? const SizedBox(height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Create Account"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0D2137)));

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {bool obscure = false, TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      decoration: _decor(hint, icon),
    );
  }

  InputDecoration _decor(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400),
    prefixIcon: Icon(icon, color: const Color(0xFF6B8EA8), size: 20),
    filled: true,
    fillColor: const Color(0xFFF4F8FB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDE8F0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1A6B9A), width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget _dropdown({required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE8F0)),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}