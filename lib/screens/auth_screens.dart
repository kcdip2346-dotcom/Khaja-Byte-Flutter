import 'package:flutter/material.dart';

import '../api.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await Api.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => RoleRouter(user: user)));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KbColors.ivory,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [KbColors.orange600, KbColors.orange400],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: KbColors.orange600.withValues(alpha: .35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset('assets/logo.png',
                          width: 88, height: 88, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text('Khājā Byte',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: KbColors.ink)),
                  const Text(
                    'ING College of Innovation and Leadership',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: KbColors.inkSoft),
                  ),
                  const SizedBox(height: 6),
                  const Text('Official Canteen App · Prices in NPR 🇳🇵',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: KbColors.inkFaint)),
                  const SizedBox(height: 26),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Login',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _email,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.mail_outline,
                                    color: KbColors.orange600),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Enter your email'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _password,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline,
                                    color: KbColors.orange600),
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Enter your password'
                                  : null,
                              onFieldSubmitted: (_) => _login(),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton(
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5))
                                  : const Text('Login'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    child: const Text('New to Khājā Byte? Create an account',
                        style: TextStyle(
                            color: KbColors.orange700,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: KbColors.orange200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('Demo accounts — one-tap login',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: KbColors.orange900)),
                        const SizedBox(height: 8),
                        _DemoLoginButton(
                            label: '👨‍🎓 Student',
                            email: 'student@ingcollege.edu.np',
                            password: 'student123',
                            onLogin: _loginWith),
                        const SizedBox(height: 6),
                        _DemoLoginButton(
                            label: '🧑‍🍳 Staff',
                            email: 'staff@ingcollege.edu.np',
                            password: 'staff123',
                            onLogin: _loginWith),
                        const SizedBox(height: 6),
                        _DemoLoginButton(
                            label: '🛡️ Admin',
                            email: 'admin@ingcollege.edu.np',
                            password: 'admin123',
                            onLogin: _loginWith),
                      ],
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

  Future<void> _loginWith(String email, String password) async {
    _email.text = email;
    _password.text = password;
    if (_formKey.currentState!.validate()) await _login();
  }
}

class _DemoLoginButton extends StatelessWidget {
  final String label;
  final String email;
  final String password;
  final Future<void> Function(String, String) onLogin;
  const _DemoLoginButton({
    required this.label,
    required this.email,
    required this.password,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => onLogin(email, password),
        style: OutlinedButton.styleFrom(
          foregroundColor: KbColors.orange900,
          backgroundColor: Colors.white,
          side: const BorderSide(color: KbColors.orange300),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.login, size: 16),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'customer';
  bool _loading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await Api.register(
          _name.text.trim(), _email.text.trim(), _password.text, _role);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => RoleRouter(user: user)),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KbAppBar(title: 'Create account'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline,
                              color: KbColors.orange600)),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline,
                              color: KbColors.orange600)),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Enter a valid email'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Password (min 6 characters)',
                          prefixIcon: Icon(Icons.lock_outline,
                              color: KbColors.orange600)),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Minimum 6 characters'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('I am a…',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: KbColors.inkSoft)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                            value: 'customer',
                            label: Text('🧑‍🎓 Student'),
                            icon: Icon(Icons.school_outlined)),
                        ButtonSegment(
                            value: 'staff',
                            label: Text('🧑‍🍳 Staff'),
                            icon: Icon(Icons.restaurant_outlined)),
                      ],
                      selected: {_role},
                      onSelectionChanged: (s) =>
                          setState(() => _role = s.first),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Create Account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
