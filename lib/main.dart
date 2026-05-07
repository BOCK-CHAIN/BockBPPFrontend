import 'package:flutter/material.dart';
import 'core/session.dart';
import 'auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'widgets/skeleton.dart';

void main() {
  runApp(const BppApp());
}

class BppApp extends StatefulWidget {
  const BppApp({super.key});

  static _BppAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_BppAppState>();

  @override
  State<BppApp> createState() => _BppAppState();
}

class _BppAppState extends State<BppApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BPP',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C3CE1)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C3CE1), brightness: Brightness.dark),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      ),
      home: const SplashRouter(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/home': (_) => const DashboardScreen(),
      },
    );
  }
}

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});
  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _showSplash = false);

    final loggedIn = await Session.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const Scaffold(
        backgroundColor: Color(0xFF6C3CE1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('BPP',
                  style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4)),
              SizedBox(height: 8),
              Text('Library · Scholar · Patents',
                  style: TextStyle(fontSize: 14, color: Colors.white60)),
            ],
          ),
        ),
      );
    }
    return const DashboardSkeleton();
  }
}
