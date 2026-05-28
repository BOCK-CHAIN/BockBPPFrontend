// lib/main.dart
import 'package:flutter/material.dart';
import 'core/session.dart';
import 'core/constants.dart';
import 'auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/book_detail_screen.dart';
import 'screens/scholar_detail_screen.dart';
import 'screens/patent_detail_screen.dart';
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
      // ── KEY FIX: stop MaterialApp from trying to parse the URL fragment
      // as a named route. We handle deep links ourselves in SplashRouter.
      initialRoute: '/',
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
      routes: {
        '/': (_) => const SplashRouter(),
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/home': (_) => const DashboardScreen(),
        '/books': (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as String? ?? '';
          return BookDetailScreen(id: id);
        },
        '/scholar': (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as String? ?? '';
          return ScholarDetailScreen(id: id);
        },
        '/patents': (ctx) {
          final id = ModalRoute.of(ctx)!.settings.arguments as String? ?? '';
          return PatentDetailScreen(id: id);
        },
      },
      onGenerateRoute: (settings) {
        final name = settings.name;
        if (name == null) return null;

        final uri = Uri.parse(name);
        final id =
            settings.arguments as String? ?? uri.queryParameters['id'] ?? '';

        switch (uri.path) {
          case '/books':
            return MaterialPageRoute(
              builder: (_) => BookDetailScreen(id: id),
              settings: settings,
            );
          case '/scholar':
            return MaterialPageRoute(
              builder: (_) => ScholarDetailScreen(id: id),
              settings: settings,
            );
          case '/patents':
            return MaterialPageRoute(
              builder: (_) => PatentDetailScreen(id: id),
              settings: settings,
            );
          default:
            return null;
        }
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

  /// Read the deep-link fragment synchronously BEFORE any async work,
  /// so the URL is captured before anything can clear or change it.
  ({String? route, String? id}) _parseDeepLink() {
    final fragment = Uri.base.fragment; // everything after "#"
    if (fragment.isNotEmpty) {
      final fragmentUri = Uri.parse(fragment);
      final path = fragmentUri.path;
      final id = fragmentUri.queryParameters['id'];
      if (id != null && id.isNotEmpty) {
        if (path == '/books') return (route: '/books', id: id);
        if (path == '/scholar') return (route: '/scholar', id: id);
        if (path == '/patents') return (route: '/patents', id: id);
      }
    }

    final path = Uri.base.path;
    if (path.isEmpty ||
        path == '/' ||
        path == '/login' ||
        path == '/dashboard') {
      return (route: null, id: null);
    }

    final uri =
        Uri.parse(path + (Uri.base.hasQuery ? '?${Uri.base.query}' : ''));
    final id = uri.queryParameters['id'];
    if (id == null || id.isEmpty) return (route: null, id: null);

    if (uri.path == '/books') return (route: '/books', id: id);
    if (uri.path == '/scholar') return (route: '/scholar', id: id);
    if (uri.path == '/patents') return (route: '/patents', id: id);

    return (route: null, id: null);
  }

  Future<void> _start() async {
    // Capture deep link immediately before any await
    final deep = _parseDeepLink();

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _showSplash = false);

    final loggedIn = await Session.isLoggedIn();
    if (!mounted) return;

    if (!loggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Always land on dashboard first
    Navigator.pushReplacementNamed(context, '/dashboard');

    // Then push detail screen on top if a deep link was found
    if (deep.route != null && deep.id != null) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        Navigator.pushNamed(context, deep.route!, arguments: deep.id);
      }
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
              Text('SCHOLAR',
                  style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4)),
              SizedBox(height: 8),
              Text('Library · Papers · Patents',
                  style: TextStyle(fontSize: 14, color: Colors.white60)),
            ],
          ),
        ),
      );
    }
    return const DashboardSkeleton();
  }
}
