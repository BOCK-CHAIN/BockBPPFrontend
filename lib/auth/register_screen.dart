// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  String _gender = 'male';
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _error;

  // password match state
  bool _passwordTouched = false;
  bool get _passwordsMatch =>
      _passwordCtrl.text == _confirmPassCtrl.text &&
      _confirmPassCtrl.text.isNotEmpty;

  static const purple = Color(0xFF6C3CE1);
  static const purpleLight = Color(0xFFEDE7FF);
  static const purpleDark = Color(0xFF4A1DB5);

  @override
  void initState() {
    super.initState();
    _confirmPassCtrl.addListener(() => setState(() => _passwordTouched = true));
    _passwordCtrl.addListener(() {
      if (_passwordTouched) setState(() {});
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.isEmpty ||
        _confirmPassCtrl.text.isEmpty ||
        _dobCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    if (!_passwordsMatch) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService.register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      dob: _dobCtrl.text.trim(),
      gender: _gender,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success']) {
      _showHexIdDialog(result['hex_id'] as String);
    } else {
      setState(() => _error = result['error']);
    }
  }

  void _showHexIdDialog(String hexId) {
    bool copied = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(28),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                    color: purpleLight, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded,
                    color: purple, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Account Created!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                'Your unique Hex ID has been generated.\nSave it — you\'ll need it to sign in.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(hexId,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: Color(0xFF1A1A1A),
                          )),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: hexId));
                        setDialogState(() => copied = true);
                        await Future.delayed(const Duration(seconds: 2));
                        setDialogState(() => copied = false);
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: copied
                            ? const Icon(Icons.check,
                                color: Colors.green,
                                size: 20,
                                key: ValueKey('check'))
                            : const Icon(Icons.copy_rounded,
                                color: purple, size: 20, key: ValueKey('copy')),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text('⚠️ Store this safely. You cannot recover it.',
                  style: TextStyle(fontSize: 11, color: Colors.orange),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Go to Sign In',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: purple),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dobCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
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
              // Purple header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 48, 28, 36),
                decoration: const BoxDecoration(
                  color: purple,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text('Create Account',
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    const Text('Join Scholar today',
                        style: TextStyle(fontSize: 15, color: Colors.white70)),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
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
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade600, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(_error!,
                                    style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 13))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Info banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A1F5C) : purpleLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: isDark ? Colors.white54 : purpleDark,
                              size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'A unique Hex ID will be generated. Use it with your password to sign in.',
                              style: TextStyle(
                                  color: isDark ? Colors.white70 : purpleDark,
                                  fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // First + Last name row
                    Row(
                      children: [
                        Expanded(
                          child: _fieldColumn(
                              'First Name',
                              labelColor,
                              _textField(
                                  controller: _firstNameCtrl,
                                  hint: 'First Name',
                                  isDark: isDark,
                                  borderColor: borderColor,
                                  cardBg: cardBg)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _fieldColumn(
                              'Last Name',
                              labelColor,
                              _textField(
                                  controller: _lastNameCtrl,
                                  hint: 'Last Name',
                                  isDark: isDark,
                                  borderColor: borderColor,
                                  cardBg: cardBg)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Email
                    _fieldColumn(
                      'Email',
                      labelColor,
                      _textField(
                        controller: _emailCtrl,
                        hint: 'Email Address',
                        keyboardType: TextInputType.emailAddress,
                        isDark: isDark,
                        borderColor: borderColor,
                        cardBg: cardBg,
                        prefixIcon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    _fieldColumn(
                      'Password',
                      labelColor,
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black),
                        decoration: _inputDecoration(
                                'Password', isDark, borderColor, cardBg,
                                prefixIcon: Icons.lock_outline_rounded)
                            .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 20,
                                color: purple),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm password + match indicator
                    _label('Confirm Password', labelColor),
                    TextField(
                      controller: _confirmPassCtrl,
                      obscureText: _obscureConfirm,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black),
                      decoration: _inputDecoration(
                              'Confirm Password', isDark, borderColor, cardBg,
                              prefixIcon: Icons.lock_person_outlined)
                          .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                              color: purple),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),

                    // Password match indicator bar
                    if (_passwordTouched) ...[
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _passwordsMatch
                              ? Colors.green.shade400
                              : Colors.red.shade300,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Row(
                          key: ValueKey(_passwordsMatch),
                          children: [
                            Icon(
                              _passwordsMatch
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 13,
                              color: _passwordsMatch
                                  ? Colors.green.shade500
                                  : Colors.red.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _passwordsMatch
                                  ? 'Passwords match'
                                  : 'Passwords do not match',
                              style: TextStyle(
                                fontSize: 11,
                                color: _passwordsMatch
                                    ? Colors.green.shade500
                                    : Colors.red.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // DOB — manual + calendar
                    _label('Date of Birth', labelColor),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _dobCtrl,
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black),
                            keyboardType: TextInputType.datetime,
                            inputFormatters: [_DobInputFormatter()],
                            decoration: _inputDecoration(
                                'YYYY-MM-DD', isDark, borderColor, cardBg,
                                prefixIcon: Icons.cake_outlined),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _pickDob,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: purple,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.calendar_month_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Gender chips
                    _label('Gender', labelColor),
                    const SizedBox(height: 4),
                    Row(
                      children: ['male', 'female', 'other'].map((g) {
                        final selected = _gender == g;
                        final icons = {
                          'male': Icons.male_rounded,
                          'female': Icons.female_rounded,
                          'other': Icons.person_rounded,
                        };
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _gender = g),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin:
                                  EdgeInsets.only(right: g != 'other' ? 8 : 0),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? purple
                                    : (isDark
                                        ? const Color(0xFF1C1C2E)
                                        : Colors.white),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected ? purple : borderColor,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(icons[g],
                                      size: 20,
                                      color: selected
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white38
                                              : Colors.grey)),
                                  const SizedBox(height: 4),
                                  Text(
                                    g[0].toUpperCase() + g.substring(1),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white60
                                              : Colors.grey.shade700),
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
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
                            : const Text('Create Account',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ',
                            style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.grey)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Sign In',
                              style: TextStyle(
                                  color: purple, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldColumn(String label, Color labelColor, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label, labelColor),
          field,
        ],
      );

  Widget _label(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(
                fontWeight: FontWeight.w500, fontSize: 13, color: color)),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    required Color borderColor,
    required Color cardBg,
    TextInputType? keyboardType,
    IconData? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: _inputDecoration(hint, isDark, borderColor, cardBg,
          prefixIcon: prefixIcon),
    );
  }

  InputDecoration _inputDecoration(
          String hint, bool isDark, Color borderColor, Color cardBg,
          {IconData? prefixIcon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: isDark ? Colors.white30 : Colors.grey, fontSize: 14),
        filled: true,
        fillColor: cardBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: purple, size: 20)
            : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: purple, width: 2)),
      );
}

// Auto-formats DOB as user types: YYYY-MM-DD
class _DobInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 8; i++) {
      if (i == 4 || i == 6) buffer.write('-');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return newValue.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
