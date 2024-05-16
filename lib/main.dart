import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:oktoast/oktoast.dart';
import 'package:supmti_events/screen/home.dart';
import 'package:supmti_events/screen/qr_code_screen.dart';
import 'package:supmti_events/styles/colors.dart';
import 'package:supmti_events/utils/box.dart' as b;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('auth');
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OKToast(
      backgroundColor: Colors.black.withOpacity(0.8),
      position: ToastPosition.bottom,
      child: MaterialApp.router(
          routerDelegate: router.routerDelegate,
          routeInformationParser: router.routeInformationParser,
          routeInformationProvider: router.routeInformationProvider,
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light().copyWith(
            textTheme: Theme.of(context).textTheme.apply(
                  fontFamily: GoogleFonts.lato().fontFamily,
                ),
            primaryColor: primaryColor,
          )),
    );
  }
}

final _key = GlobalKey<NavigatorState>();
final router = GoRouter(
    navigatorKey: _key,
    debugLogDiagnostics: true,
    initialLocation: "/login",
    refreshListenable: b.Box.listenToken(),
    routes: [
      GoRoute(
        path: "/login",
        redirect: _loggedGuard,
        builder: (context, state) => const Home(),
      ),
      GoRoute(
          path: "/",
          redirect: _authGuard,
          builder: (context, state) => const QrScanScreen()),
    ]);

FutureOr<String?> _authGuard(BuildContext context, GoRouterState state) {
  final token = b.Box.getToken();
  if (token == null) {
    return "/login";
  }
  return null;
}

FutureOr<String?> _loggedGuard(BuildContext context, GoRouterState state) {
  final token = b.Box.getToken();
  if (token != null) {
    return "/";
  }
  return null;
}
