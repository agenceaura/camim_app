import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/ranking_screen.dart';
import 'screens/championships_screen.dart';
import 'screens/main_shell.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/calendar_detail_screen.dart';
import 'screens/edit_event_screen.dart';
import 'screens/costs_screen.dart';
import 'screens/admin_pilots_list_screen.dart';
import 'screens/admin_edit_pilot_screen.dart';
import 'screens/pre_inscription_screen.dart';
import 'screens/admin_dates_list_screen.dart';
import 'screens/dates_history_screen.dart';
import 'screens/live_event_screen.dart';
import 'screens/admin_live_event_screen.dart';
import 'screens/regulations_screen.dart';
import 'screens/birthday_calendar_screen.dart';
import 'screens/admin_notifications_screen.dart';
import 'screens/admin_check_in_logs_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Supabase.initialize(
      url: 'https://szfnydveuhirywfhryoq.supabase.co',
      anonKey: 'sb_publishable_z9-XI_FqQ-UoRHGHjPVNmg_OJuynPWf',
    );

    // Inicializar Notificaciones
    await NotificationService().init();
  } catch (e) {
    debugPrint('Error durante la inicialización: $e');
  }
  
  initializeDateFormatting('es_ES', null).then((_) => runApp(const CamimApp()));
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const MainShell();
        }
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainShell(),
    ),
    GoRoute(
      path: '/ranking',
      builder: (context, state) => const RankingScreen(),
    ),
    GoRoute(
      path: '/calendar_detail',
      builder: (context, state) => const CalendarDetailScreen(),
    ),
    GoRoute(
      path: '/edit_event',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return EditEventScreen(initialEvent: extra);
      },
    ),
    GoRoute(
      path: '/costs',
      builder: (context, state) => const CostsScreen(),
    ),
    GoRoute(
      path: '/admin_pilots',
      builder: (context, state) => const AdminPilotsListScreen(),
    ),
    GoRoute(
      path: '/pre_inscription',
      builder: (context, state) => const PreInscriptionScreen(),
    ),
    GoRoute(
      path: '/admin_edit_pilot',
      builder: (context, state) {
        final profile = state.extra as Map<String, dynamic>;
        return AdminEditPilotScreen(profile: profile);
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/scanner',
      builder: (context, state) => const ScannerScreen(),
    ),
    GoRoute(
      path: '/edit_profile',
      builder: (context, state) {
        final profile = state.extra as Map<String, dynamic>?;
        return EditProfileScreen(initialProfile: profile);
      },
    ),
    GoRoute(
      path: '/championships',
      builder: (context, state) => const ChampionshipsScreen(),
    ),
    GoRoute(
      path: '/admin_dates_list',
      builder: (context, state) => const AdminDatesListScreen(),
    ),
    GoRoute(
      path: '/dates_history',
      builder: (context, state) => const DatesHistoryScreen(),
    ),
    GoRoute(
      path: '/live_event',
      builder: (context, state) => const LiveEventScreen(),
    ),
    GoRoute(
      path: '/admin_live_event',
      builder: (context, state) => const AdminLiveEventScreen(),
    ),
    GoRoute(
      path: '/admin_notifications',
      builder: (context, state) => const AdminNotificationsScreen(),
    ),
    GoRoute(
      path: '/birthday_calendar',
      builder: (context, state) => const AppCalendarScreen(),
    ),
    GoRoute(
      path: '/admin_check_in_logs',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>;
        return AdminCheckInLogsScreen(
          eventId: extras['eventId'],
          eventTitle: extras['eventTitle'],
        );
      },
    ),
    GoRoute(
      path: '/regulations',
      builder: (context, state) => const RegulationsScreen(),
    ),
  ],
);

class CamimApp extends StatelessWidget {
  const CamimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CAMIM App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}