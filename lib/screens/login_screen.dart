import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _setLoading(bool v) {
    if (mounted) setState(() => _isLoading = v);
  }

  Future<void> loginUser() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showSnack("Please fill in all fields", isError: true);
      return;
    }
    _setLoading(true);
    try {
      UserCredential cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      // ✅ BYPASS email verification for existing unverified users
      // Comment the block below to disable email verification requirement
      if (!cred.user!.emailVerified) {
        _showSnack("Please verify your email. Check your inbox.", isError: true);
        // Resend verification
        await cred.user!.sendEmailVerification();
        await FirebaseAuth.instance.signOut();
        _setLoading(false);
        return;
      }

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(cred.user!.uid)
          .get();

      if (!mounted) return;

      String gender = "Male";
      if (doc.exists) {
        gender = (doc.data() as Map<String, dynamic>)["gender"] ?? "Male";
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(gender: gender)),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = "Login failed";
      switch (e.code) {
        case 'user-not-found': msg = "No account found with this email"; break;
        case 'wrong-password': msg = "Incorrect password"; break;
        case 'invalid-email': msg = "Invalid email address"; break;
        case 'too-many-requests': msg = "Too many attempts. Try later"; break;
        case 'invalid-credential': msg = "Invalid email or password"; break;
      }
      _showSnack(msg, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnack("Login failed. Try again.", isError: true);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) { _setLoading(false); return; }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential cred =
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;

      String gender = "Male";
      final ref = FirebaseFirestore.instance.collection("users").doc(cred.user!.uid);

      if (cred.additionalUserInfo?.isNewUser == true) {
        await ref.set({
          "name": cred.user!.displayName ?? "",
          "email": cred.user!.email,
          "gender": "Male",
          "emergency_contact": "",
          "blood_group": "",
          "allergies": "",
          "chronic_conditions": "",
          "created_at": Timestamp.now(),
        });
      } else {
        final doc = await ref.get();
        if (!mounted) return;
        if (doc.exists) {
          gender = (doc.data() as Map<String, dynamic>)["gender"] ?? "Male";
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(gender: gender)),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack("Google Sign-In failed. Try again.", isError: true);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> forgotPassword() async {
    if (emailController.text.trim().isEmpty) {
      _showSnack("Enter your email first", isError: true);
      return;
    }
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailController.text.trim());
      if (!mounted) return;
      _showSnack("Reset email sent! Check your inbox.", isError: false);
    } catch (_) {
      if (!mounted) return;
      _showSnack("Failed to send reset email", isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
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
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Logo + Title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Image.asset("assets/lifeline_logo.png"),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Sign in to your LifeLine account",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Card Form
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("Email Address"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecor("your@email.com", Icons.email_outlined),
                        ),

                        const SizedBox(height: 20),

                        _label("Password"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          decoration: _inputDecor("••••••••", Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xFF6B8EA8),
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: forgotPassword,
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: Color(0xFF1A6B9A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : loginUser,
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                                : const Text("Sign In"),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text("or", style: TextStyle(color: Colors.grey.shade500)),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ]),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : signInWithGoogle,
                            icon: const Text("G", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF4285F4))),
                            label: const Text(
                              "Continue with Google",
                              style: TextStyle(
                                color: Color(0xFF0D2137),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: RichText(
                        text: const TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: Colors.white70),
                          children: [
                            TextSpan(
                              text: "Register",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF0D2137),
    ),
  );

  InputDecoration _inputDecor(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400),
    prefixIcon: Icon(icon, color: const Color(0xFF6B8EA8), size: 20),
    filled: true,
    fillColor: const Color(0xFFF4F8FB),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDDE8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF1A6B9A), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}