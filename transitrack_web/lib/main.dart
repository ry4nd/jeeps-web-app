import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:transitrack_web/MenuController.dart';
import 'package:transitrack_web/style/constants.dart';
import 'package:transitrack_web/pages/dashboard_page.dart';
import 'package:transitrack_web/pages/share_page.dart';
import 'firebase_options.dart';

// Entry point of the Flutter web application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific configuration.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

// Routing configuration using go_router
final _router = GoRouter(
  routes: [
    // Route for Dashboard Page
    GoRoute(
      path: '/',
      builder: (context, state) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MenuControllers()),
        ],
        child: const Dashboard(),
      ),
    ),
    // Route for Share Page
    GoRoute(
      path: '/share',
      builder: (context, state) {
        final shareId = state.uri.queryParameters['share_id'];
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => MenuControllers()),
          ],
          child: SharePage(shareId: shareId),
        );
      },
    ),
  ],
);

// Root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'JeePS',

      // Use go_router's configuration
      routerConfig: _router,

      // Global theme settings for the app
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Constants.secondaryColor,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: Colors.white),
        canvasColor: Constants.secondaryColor,
      ),
    );
  }
}
