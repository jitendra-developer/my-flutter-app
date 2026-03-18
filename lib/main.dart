import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/chat_page.dart';
import 'package:myapp/chat_provider.dart';
import 'package:myapp/login.dart';
import 'package:myapp/login_page.dart';
import 'package:myapp/onboarding_screen.dart';
import 'package:myapp/register.dart';
import 'package:myapp/screens/otp_verification_screen.dart';
import 'package:myapp/screens/reset_password_screen.dart';
import 'package:myapp/welcome_page.dart';
import 'package:myapp/screens/settings_page.dart';
import 'package:myapp/screens/language_selection_page.dart';
import 'package:myapp/screens/profile_page.dart';
import 'package:myapp/screens/learn_page.dart';
import 'package:myapp/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    developer.log('Error loading .env file', error: e);
  }

  // Check if token exists to determine initial route
  final apiService = ApiService();
  final hasToken = await apiService.hasToken();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          return ChatProvider(initialAuthenticated: hasToken);
        }),
      ],
      child: MyApp(initialRoute: hasToken ? '/chat' : '/welcome'),
    ),
  );
}

class MyApp extends StatefulWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _router = GoRouter(
      initialLocation: widget.initialRoute,
      refreshListenable: Provider.of<ChatProvider>(context, listen: false),
      routes: [
        GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(path: '/chat', builder: (context, state) => const ChatPage()),
        GoRoute(
          path: '/login',
          builder: (context, state) => const AuthHubPage(),
        ),
        GoRoute(
          path: '/email-login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/otp-verification',
          builder: (context, state) {
            final email = state.extra as String?;
            if (email == null) {
              return const AuthHubPage();
            }
            return OtpVerificationScreen(email: email);
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/language-selection',
          builder: (context, state) => const LanguageSelectionPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final email = state.extra as String? ?? '';
            return ResetPasswordScreen(email: email);
          },
        ),
        GoRoute(
          path: '/learn',
          builder: (context, state) => const LearnPage(),
        ),
      ],
      redirect: (context, state) async {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        final hasSession = chatProvider.isAuthenticated;
        
        final isAuthRoute =
            state.uri.path == '/login' ||
            state.uri.path == '/email-login' ||
            state.uri.path == '/register' ||
            state.uri.path.startsWith('/otp-verification');

        final isPublicRoute =
            state.uri.path == '/welcome' || state.uri.path == '/onboarding';

        if (!hasSession) {
          // If NOT logged in:
          // Allow access to welcome, onboarding, and auth routes
          if (isPublicRoute || isAuthRoute) {
            return null;
          }
          // Redirect everything else to login
          return '/login';
        } else {
          // If logged in:
          // Prevent access to login/onboarding, redirect to chat
          if (isAuthRoute || isPublicRoute) {
            return '/chat';
          }
          // Allow all other routes (chat, settings, etc.)
          return null;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return MaterialApp.router(
          title: 'Vakya Pro',
          locale: chatProvider.locale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('hi', 'IN'),
            Locale('mr', 'IN'),
            Locale('gu', 'IN'),
            Locale('ta', 'IN'),
            Locale('te', 'IN'),
            Locale('bn', 'IN'),
            Locale('kn', 'IN'),
            Locale('ml', 'IN'),
            Locale('pa', 'IN'),
          ],
          theme: ThemeData.dark().copyWith(
            primaryColor: const Color(0xFF4A60D4),
            scaffoldBackgroundColor: const Color(0xFF13131A),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF4A60D4),
              secondary: Color(0xFF3B2E7E),
              error: Colors.redAccent,
            ),
          ),
          builder: (context, child) {
            return Container(
              color: const Color(0xFF13131A),
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ClipRect(child: child),
              ),
            );
          },
          routerConfig: _router,
        );
      },
    );
  }
}
