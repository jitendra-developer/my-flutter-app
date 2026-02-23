import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/chat_page.dart';
import 'package:myapp/chat_provider.dart';
import 'package:myapp/login.dart';
import 'package:myapp/login_page.dart';
import 'package:myapp/onboarding_screen.dart';
import 'package:myapp/register.dart';
import 'package:myapp/screens/otp_verification_screen.dart';
import 'package:myapp/welcome_page.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;

// GoRouter refresh stream to rebuild the router when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.listen((_) {
      developer.log('Auth state changed, notifying router.');
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  } catch (e) {
    developer.log(
      'Error during initialization: $e\n'
      'Please ensure you have a .env file with valid SUPABASE_URL and SUPABASE_ANON_KEY.',
      error: e,
      level: 1000, // SEVERE
    );
    // Run the app with an error message screen if initialization fails
    runApp(const InitializationErrorApp());
    return;
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ChatProvider(),
      child: const MyApp(),
    ),
  );
}

// A simple app to display a critical error message
class InitializationErrorApp extends StatelessWidget {
  const InitializationErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.redAccent,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Error: Could not initialize the application.\nCheck your .env file and debug console for more details.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    final authStream = Supabase.instance.client.auth.onAuthStateChange;

    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const WelcomePage()),
        GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
        GoRoute(path: '/chat', builder: (context, state) => const ChatPage()),
        GoRoute(path: '/login', builder: (context, state) => const AuthHubPage()),
        GoRoute(path: '/email-login', builder: (context, state) => const LoginPage()),
        GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
        GoRoute(
          path: '/otp-verification',
          builder: (context, state) {
            final email = state.extra as String?;
            if (email == null) {
              // If email is not provided, redirect to a safe page like the login hub
              return const AuthHubPage();
            }
            return OtpVerificationScreen(email: email);
          },
        ),
      ],
      redirect: (context, state) {
        final session = Supabase.instance.client.auth.currentSession;
        final hasSession = session != null;
        developer.log('Router Redirect: User has session: $hasSession, Current Location: ${state.uri}');

        final isAuthRoute = state.uri.path == '/login' ||
            state.uri.path == '/email-login' ||
            state.uri.path == '/register' ||
            state.uri.path.startsWith('/otp-verification');

        final isPublicRoute = state.uri.path == '/' || state.uri.path == '/onboarding';

        // SCENARIO 1: USER IS NOT LOGGED IN
        if (!hasSession) {
          // If the user is on a public page or an authentication page, let them stay.
          if (isPublicRoute || isAuthRoute) {
            return null;
          }
          // For any other page, redirect them to the login hub.
          return '/login';
        }

        // SCENARIO 2: USER IS LOGGED IN
        // If the logged-in user is on an auth page or a public intro page, they should be moved to the chat.
        if (isAuthRoute || isPublicRoute) {
          developer.log('User is logged in and on an auth/public route, redirecting to /chat');
          return '/chat';
        }

        // Otherwise, the user is logged in and on a valid page. No redirect needed.
        return null;
      },
      refreshListenable: GoRouterRefreshStream(authStream),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Totan AI',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: Colors.deepPurpleAccent,
          error: Colors.redAccent,
        ),
      ),
      routerConfig: _router,
    );
  }
}
