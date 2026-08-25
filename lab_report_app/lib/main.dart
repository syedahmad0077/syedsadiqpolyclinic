import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/hive_database_service.dart';
import 'screens/dashboard_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive Database and seed default test templates
  await HiveDatabaseService.instance.init();

  runApp(
    const ProviderScope(
      child: SyedSadiqLabApp(),
    ),
  );
}

class SyedSadiqLabApp extends StatelessWidget {
  const SyedSadiqLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.clinicName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryTeal,
          primary: AppConstants.primaryTeal,
          secondary: AppConstants.secondaryNavy,
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
