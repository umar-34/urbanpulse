import 'dart:ui';
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

  runApp(
    ChangeNotifierProvider(
      create: (_) => ReportProvider(),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: const SplashScreen(),
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

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _capsuleCtrl;
  late Animation<double> _capsuleAnim;

  static const _navItems = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NavItem(Icons.description_outlined, Icons.description_rounded, 'Reports'),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  final List<Widget> _screens = const [
    HomeScreen(),
    MyReportsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _capsuleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _capsuleAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _capsuleCtrl, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _capsuleCtrl.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    final oldIndex = _currentIndex;
    setState(() => _currentIndex = index);
    _capsuleAnim = Tween<double>(
      begin: oldIndex.toDouble(),
      end: index.toDouble(),
    ).animate(
      CurvedAnimation(parent: _capsuleCtrl, curve: Curves.easeInOutCubic),
    );
    _capsuleCtrl
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // body goes behind the floating bar
      body: _screens[_currentIndex],
      bottomNavigationBar: _GlassNavBar(
        currentIndex: _currentIndex,
        capsuleAnim: _capsuleAnim,
        navItems: _navItems,
        onTap: _onTabTap,
      ),
    );
  }
}

class _NavItem {
  final IconData outlineIcon;
  final IconData filledIcon;
  final String label;
  const _NavItem(this.outlineIcon, this.filledIcon, this.label);
}

class _GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final Animation<double> capsuleAnim;
  final List<_NavItem> navItems;
  final ValueChanged<int> onTap;

  const _GlassNavBar({
    required this.currentIndex,
    required this.capsuleAnim,
    required this.navItems,
    required this.onTap,
  });

  static const _primary = Color(0xFF064554);
  static const _barHeight = 64.0;
  static const _hPad = 20.0; // horizontal page margin
  static const _vPad = 16.0; // distance above system nav

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final totalHeight = _barHeight + _vPad + bottomInset;

    return SizedBox(
      height: totalHeight,
      child: Padding(
        padding: EdgeInsets.only(
          left: _hPad,
          right: _hPad,
          bottom: _vPad + bottomInset,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: _barHeight,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.62),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: _primary.withOpacity(0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: LayoutBuilder(builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / navItems.length;
                return AnimatedBuilder(
                  animation: capsuleAnim,
                  builder: (context, child) {
                    final capsuleLeft = capsuleAnim.value * itemWidth + 6;
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Positioned(
                          left: capsuleLeft,
                          child: Container(
                            width: itemWidth - 12,
                            height: _barHeight - 16,
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: _primary.withOpacity(0.22),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(navItems.length, (i) {
                            final item = navItems[i];
                            final isActive = currentIndex == i;
                            return Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => onTap(i),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      transitionBuilder: (child, anim) =>
                                          ScaleTransition(
                                              scale: anim, child: child),
                                      child: Icon(
                                        isActive
                                            ? item.filledIcon
                                            : item.outlineIcon,
                                        key: ValueKey(isActive),
                                        color: isActive
                                            ? _primary
                                            : _primary.withOpacity(0.38),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    AnimatedDefaultTextStyle(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isActive
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isActive
                                            ? _primary
                                            : _primary.withOpacity(0.38),
                                        letterSpacing: 0.2,
                                      ),
                                      child: Text(item.label),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
