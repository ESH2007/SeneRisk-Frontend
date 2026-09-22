import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/map/presentation/offline_maps_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/create_report_screen.dart';
import 'screens/help_center_screen.dart';
import 'screens/home_map_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/report_detail_screen.dart';
import 'screens/search_place_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/terms_screen.dart';
import 'screens/verify_reports_screen.dart';
import 'screens/welcome_screen.dart';

Page<void> _modal(GoRouterState state, Widget child) =>
    MaterialPage(key: state.pageKey, fullscreenDialog: true, child: child);

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const WelcomeScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    GoRoute(path: '/terms', builder: (_, _) => const TermsScreen()),
    GoRoute(
      path: '/home',
      builder: (_, state) => HomeMapScreen(
        centrarLat: double.tryParse(state.uri.queryParameters['lat'] ?? ''),
        centrarLng: double.tryParse(state.uri.queryParameters['lng'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (_, state) => _modal(state, const SearchPlaceScreen()),
    ),
    GoRoute(
      path: '/report/new',
      pageBuilder: (_, state) => _modal(state, const CreateReportScreen()),
    ),
    GoRoute(
      path: '/report/:id',
      builder: (_, state) => ReportDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(path: '/alerts', builder: (_, _) => const AlertsScreen()),
    GoRoute(path: '/verify', builder: (_, _) => const VerifyReportsScreen()),
    GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/maps', builder: (_, _) => const OfflineMapsScreen()),
    GoRoute(path: '/help', builder: (_, _) => const HelpCenterScreen()),
  ],
);
