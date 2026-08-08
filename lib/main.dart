import 'package:flutter/material.dart';

import 'api.dart';
import 'screens/auth_screens.dart';
import 'screens/customer_shell.dart';
import 'screens/admin_shell.dart';
import 'screens/staff_shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KhajaByteApp());
}

class KhajaByteApp extends StatefulWidget {
  const KhajaByteApp({super.key});

  @override
  State<KhajaByteApp> createState() => _KhajaByteAppState();
}

class _KhajaByteAppState extends State<KhajaByteApp> {
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    Api.restoreSession().then((ok) {
      if (mounted) setState(() => _restoring = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khājā Byte',
      debugShowCheckedModeBanner: false,
      theme: kbTheme(),
      home: _restoring ? const _SplashScreen() : const _Root(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KbColors.ivory,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/logo.png',
                  width: 88, height: 88, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            const Text('Khājā Byte',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: KbColors.orange800)),
            const SizedBox(height: 14),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: KbColors.orange600),
            ),
          ],
        ),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final u = Api.user;
    if (u == null) return const LoginScreen();
    if (u.isAdmin) return const AdminShell();
    if (u.isStaff) return const StaffShell();
    return const CustomerShell();
  }
}

class RoleRouter extends StatelessWidget {
  final User user;
  const RoleRouter({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if (user.isAdmin) return const AdminShell();
    if (user.isStaff) return const StaffShell();
    return const CustomerShell();
  }
}
