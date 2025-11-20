import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'blocs/auth_bloc.dart';
import 'blocs/auth_event.dart';
import 'blocs/auth_state.dart';
import 'blocs/cart_bloc.dart';
import 'blocs/menu_bloc.dart';
import 'blocs/order_bloc.dart';
import 'blocs/notification_bloc.dart';
import 'blocs/recommendation_bloc.dart';
import 'blocs/chat_bloc.dart';
import 'l10n/app_localizations.dart';
import 'l10n/language_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/client/client_home.dart';
import 'screens/admin/admin_home.dart';
import 'screens/waiter/waiter_home.dart';
import 'screens/courier/deliver_home.dart';
import 'screens/admin/directors_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) {
                  final authBloc = AuthBloc();
                  // Check auth status on app start for auto-login
                  authBloc.add(const CheckAuthStatus());
                  return authBloc;
                },
              ),
              BlocProvider(create: (context) => CartBloc()),
              BlocProvider(create: (context) => MenuBloc()),
              BlocProvider(create: (context) => OrderBloc()),
              BlocProvider(create: (context) => NotificationBloc()),
              BlocProvider(create: (context) => RecommendationBloc()),
              BlocProvider(create: (context) => ChatBloc()),
            ],
            child: MaterialApp(
              title: 'Food Flow',
              debugShowCheckedModeBanner: false,

              // Localization
              locale: languageProvider.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              // Theme
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFFFF6B35),
                  brightness: Brightness.light,
                ),
                primaryColor: const Color(0xFFFF6B35),
                scaffoldBackgroundColor: const Color(0xFFF8F9FA),

                // App Bar Theme
                appBarTheme: const AppBarTheme(
                  elevation: 0,
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  foregroundColor: Color(0xFF2D3142),
                  systemOverlayStyle: SystemUiOverlayStyle.dark,
                ),

                // Card Theme
                cardTheme: CardThemeData(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  surfaceTintColor: Colors.white,
                ),

                // Input Decoration Theme
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF6B35),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),

                // Elevated Button Theme
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Text Button Theme
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B35),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                // Icon Theme
                iconTheme: const IconThemeData(
                  color: Color(0xFF2D3142),
                ),

                // Bottom Navigation Bar Theme
                bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                  selectedItemColor: Color(0xFFFF6B35),
                  unselectedItemColor: Colors.grey,
                  showUnselectedLabels: true,
                  type: BottomNavigationBarType.fixed,
                  elevation: 8,
                ),

                // Text Theme
                textTheme: const TextTheme(
                  displayLarge: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                  displayMedium: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                  displaySmall: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                  headlineMedium: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                  titleLarge: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                  bodyLarge: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D3142),
                  ),
                  bodyMedium: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5D6171),
                  ),
                ),

                // Floating Action Button Theme
                floatingActionButtonTheme: const FloatingActionButtonThemeData(
                  backgroundColor: Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  elevation: 4,
                ),
              ),

              home: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    );
                  }

                  if (state is AuthAuthenticated) {
                    // Navigate based on user role
                    switch (state.user.role) {
                      case 'client':
                        return const ClientHome();
                      case 'admin':
                        return const AdminHome();
                      case 'waiter':
                        return const WaiterHome();
                      case 'courier':
                        return const DeliverHome();
                      case 'director':
                        return const DirectorHome();
                      default:
                        return const ClientHome();
                    }
                  }

                  return const LoginScreen();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}