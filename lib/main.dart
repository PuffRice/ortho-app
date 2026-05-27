import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/app_routes.dart';
import 'config/supabase_config.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/credentials_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/manage_accounts_screen.dart';
import 'screens/manage_categories_screen.dart';
import 'screens/profile_screen.dart';
import 'services/local_db.dart';
import 'services/local_user_migration.dart';
import 'services/supabase_service.dart';
import 'services/sync_service.dart';
import 'services/timestamp_repair_service.dart';
import 'services/user_identity.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isar = await LocalDb.instance.open();
  final profile = await UserIdentityService.instance.getProfile();
  await LocalUserMigration(isar).migrateTo(profile.userId);
  await TimestampRepairService(isar: isar).repairLocal(userId: profile.userId);
  if (_supabaseConfigured()) {
    await SupabaseService().initialize(
      supabaseUrl: SUPABASE_URL,
      supabaseAnonKey: SUPABASE_ANON_KEY,
    );
    await SyncService.initialize(
      isar: isar,
      client: SupabaseService().client,
    );
  }
  runApp(const MainApp());
}

bool _supabaseConfigured() {
  return SUPABASE_URL != 'YOUR_SUPABASE_URL' &&
      SUPABASE_ANON_KEY != 'YOUR_SUPABASE_ANON_KEY';
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: const Color(0xFF0F172A),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        fontFamily: 'Inter',
      ),
      routes: {
        AppRoutes.addTransaction: (_) => const AddTransactionScreen(),
        AppRoutes.manageAccounts: (_) => const ManageAccountsScreen(),
        AppRoutes.manageCategories: (_) => const ManageCategoriesScreen(),
      },
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DashboardScreen(),
    const CredentialsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: _screens,
            ),
            Positioned(
              bottom: 72,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.addTransaction);
                  },
                  backgroundColor: const Color(0xFF7c3aed),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
            // Fixed glassmorphic navbar
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildFloatingNavBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(0, Icons.home, 'Home'),
              _buildNavBarItem(1, Icons.bar_chart, 'Dashboard'),
              _buildNavBarItem(2, Icons.credit_card, 'Credentials'),
              _buildNavBarItem(3, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () async {
        if (_selectedIndex == index) return;
        HapticFeedback.selectionClick();
        setState(() {
          _selectedIndex = index;
        });
        await _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
        );
      },
      child: AnimatedScale(
        scale: isSelected ? 1.08 : 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF7c3aed).withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.88,
                    end: 1,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Icon(
              icon,
              key: ValueKey('$label-$isSelected'),
              color: isSelected ? Colors.white : Colors.grey.shade500,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
