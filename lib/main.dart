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
import 'l10n/theme_provider.dart';
import 'l10n/app_theme.dart';
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<LanguageProvider, ThemeProvider>(
        builder: (context, languageProvider, themeProvider, child) {
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
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,

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