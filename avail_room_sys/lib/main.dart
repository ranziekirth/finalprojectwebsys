// lib/main.dart - FINAL COMPLETE VERSION
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/room_provider.dart';
import 'providers/teacher_provider.dart';
import 'providers/subject_provider.dart';
import 'providers/booking_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/room_management_screen.dart';
import 'screens/teacher_management_screen.dart';
import 'screens/subject_management_screen.dart';
import 'screens/auto_scheduler_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()..init()),
        ChangeNotifierProvider(create: (_) => TeacherProvider()..init()),
        ChangeNotifierProvider(create: (_) => SubjectProvider()..init()),
        ChangeNotifierProvider(create: (_) => BookingProvider()..init()),
      ],
      child: const RoomAvailabilityApp(),
    ),
  );
}

class RoomAvailabilityApp extends StatelessWidget {
  const RoomAvailabilityApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-Time Room Availability System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/room-management': (context) => const RoomManagementScreen(),
        '/teacher-management': (context) => const TeacherManagementScreen(),
        '/subject-management': (context) => const SubjectManagementScreen(),
        '/auto-scheduler': (context) => const AutoSchedulerScreen(),
      },
    );
  }
}