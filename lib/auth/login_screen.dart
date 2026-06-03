// lib/auth/login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../core/session.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _hexIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  static const purple = Color(0xFF6C3CE1);
  static const purpleLight = Color(0xFFEDE7FF);
  static const purpleDark = Color(0xFF4A1DB5);

  @override
  void dispose() {
    _hexIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_hexIdCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Hex ID and password are required');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService.login(
      hexId: _hexIdCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success']) {
      final data = result['data'];
      await Session.save(
        sessionId: data['session_id'],
        userId: data['user']['id'],
        firstName: data['user']['first_name'],
        email: data['user']['email'],
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      setState(() => _error = result['error']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F1A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final labelColor = isDark ? Colors.white70 : const Color(0xFF333333);
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Purple header ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 56, 28, 40),
                decoration: const BoxDecoration(
                  color: purple,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scholar',
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    SizedBox(height: 4),
                    Text('Sign in to your account',
                        style: TextStyle(fontSize: 15, color: Colors.white70)),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error banner
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(_error!,
                            style: TextStyle(
                                color: Colors.red.shade700, fontSize: 13)),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Info hint
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A1F5C) : purpleLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Use the Hex ID you received during registration.',
                        style: TextStyle(
                            color: isDark ? Colors.white70 : purpleDark,
                            fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Hex ID
                    Text('Hex ID',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: labelColor)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _hexIdCtrl,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        letterSpacing: 1.2,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Your 16-character Hex ID',
                        hintStyle: TextStyle(
                            color: isDark ? Colors.white30 : Colors.grey,
                            fontSize: 14,
                            fontFamily: 'monospace'),
                        filled: true,
                        fillColor: cardBg,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: purple, width: 2)),
                        prefixIcon: const Icon(Icons.tag_rounded,
                            color: purple, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    Text('Password',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: labelColor)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      onSubmitted: (_) => _login(),
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(
                            color: isDark ? Colors.white30 : Colors.grey,
                            fontSize: 14),
                        filled: true,
                        fillColor: cardBg,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: purple, width: 2)),
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: purple, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                              color: purple),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Sign in button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Sign In',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ",
                            style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.grey)),
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RegisterScreen())),
                          child: const Text('Register',
                              style: TextStyle(
                                  color: purple, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
