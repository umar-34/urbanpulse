import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'providers/report_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_report_screen.dart';
import 'screens/report_detail_screen.dart';
import 'screens/my_reports_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/all_reports_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/auth/profile_completion_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // ─── App Startup Profile Check ───────────────────────────────────────────
  // If the user closed the app without completing their profile, log them out
  // so they are routed back to the Welcome Screen instead of entering the app.
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      final phone = data?['phoneNumber'] as String?;
      final city = data?['city'] as String?;

      if (phone == null || phone.isEmpty || city == null || city.isEmpty) {
        await FirebaseAuth.instance.signOut();
        try {
          await GoogleSignIn().signOut();
        } catch (_) {}
      }
    } catch (_) {
      // Ignore network errors to prevent hanging the app on startup
    }
  }
  // ─────────────────────────────────────────────────────────────────────────

  runApp(
    ChangeNotifierProvider(
      create: (_) => ReportProvider()..load(),
      child: const UrbanPulseApp(),
    ),
  );
}

class UrbanPulseApp extends StatelessWidget {
  const UrbanPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UrbanPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF064554),
          primary: const Color(0xFF064554),
          secondary: const Color(0xFF00BFA5),
          surface: const Color(0xFFF0F7F8),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFF064554),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF064554),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Roboto',
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F7F8),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF064554),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 3,
            shadowColor: const Color(0xFF064554),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF064554), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const MainNavigation();
          }
          return const WelcomeScreen();
        },
      ),
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/welcome': (_) => const WelcomeScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/home': (_) => const MainNavigation(),
        '/main': (_) => const MainNavigation(),
        '/create-report': (_) => const CreateReportScreen(),
        '/report-detail': (_) => const ReportDetailScreen(),
        '/all-reports': (_) => const AllReportsScreen(),
        '/notifications': (_) => const NotificationsScreen(),
        '/profile-completion': (_) => const ProfileCompletionScreen(),
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MyReportsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.description_outlined, Icons.description_rounded, 'My Reports'),
                _buildNavItem(2, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    const primary = Color(0xFF064554);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? primary.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? primary : const Color(0xFF94A3B8),
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? primary : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
