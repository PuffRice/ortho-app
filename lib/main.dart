import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/app_colors.dart';
import 'config/app_routes.dart';
import 'config/supabase_config.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/credentials_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/manage_accounts_screen.dart';
import 'screens/manage_categories_screen.dart';
import 'screens/personal_information_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'services/local_db.dart';
import 'services/local_user_migration.dart';
import 'services/supabase_service.dart';
import 'services/sync_service.dart';
import 'services/timestamp_repair_service.dart';
import 'services/user_identity.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

Future<void> _initializeApp() async {
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
}

bool _supabaseConfigured() {
  return SUPABASE_URL != 'YOUR_SUPABASE_URL' &&
      SUPABASE_ANON_KEY != 'YOUR_SUPABASE_ANON_KEY';
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = Future.wait<void>([
      _initializeApp(),
      Future<void>.delayed(const Duration(milliseconds: 1100)),
    ]);
  }

  void _retryBootstrap() {
    setState(() {
      _bootstrapFuture = Future.wait<void>([
        _initializeApp(),
        Future<void>.delayed(const Duration(milliseconds: 700)),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ortho : Intelligent Finances',
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: const Color(0xFF0F172A),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.interTextTheme(),
        primaryTextTheme: GoogleFonts.interTextTheme(),
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      routes: {
        AppRoutes.addTransaction: (_) => const AddTransactionScreen(),
        AppRoutes.transactionHistory: (_) => const TransactionHistoryScreen(),
        AppRoutes.manageAccounts: (_) => const ManageAccountsScreen(),
        AppRoutes.manageCategories: (_) => const ManageCategoriesScreen(),
        AppRoutes.personalInformation: (_) => const PersonalInformationScreen(),
      },
      home: FutureBuilder<void>(
        future: _bootstrapFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _StartupErrorScreen(onRetry: _retryBootstrap);
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: snapshot.connectionState == ConnectionState.done
                ? const MainNavigation(key: ValueKey('main-navigation'))
                : const _StartupSplash(key: ValueKey('startup-splash')),
          );
        },
      ),
    );
  }
}

class _StartupSplash extends StatefulWidget {
  const _StartupSplash({super.key});

  @override
  State<_StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<_StartupSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _entrance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _entrance = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.62, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.18, -0.28),
            radius: 1.08,
            colors: [
              Color(0xFF241149),
              AppColors.bgSecondary,
              AppColors.bgPrimary,
            ],
            stops: [0, 0.46, 1],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SplashAuraPainter(progress: _controller.value),
                );
              },
            ),
            Center(
              child: FadeTransition(
                opacity: _entrance,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.94, end: 1).animate(_entrance),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1 + (_controller.value * 0.025),
                            child: child,
                          );
                        },
                        child: const _SplashMark(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Ortho : Intelligent Finances',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Secure money clarity',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 58,
              child: Center(
                child: SizedBox(
                  width: 112,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentCoral,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
            Color(0xFFFF7A45),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.42),
            blurRadius: 42,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: AppColors.accentCoral.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(31),
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: const CustomPaint(
          painter: _FinanceMarkPainter(),
        ),
      ),
    );
  }
}

class _FinanceMarkPainter extends CustomPainter {
  const _FinanceMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final chartPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.white, Color(0xFFFFD0C8)],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final coinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;

    final left = size.width * 0.24;
    final right = size.width * 0.76;
    final top = size.height * 0.29;
    final bottom = size.height * 0.72;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, bottom),
        const Radius.circular(12),
      ),
      gridPaint,
    );

    final chart = Path()
      ..moveTo(size.width * 0.29, size.height * 0.62)
      ..lineTo(size.width * 0.43, size.height * 0.53)
      ..lineTo(size.width * 0.53, size.height * 0.58)
      ..lineTo(size.width * 0.72, size.height * 0.41);
    canvas.drawPath(chart, chartPaint);
    canvas.drawCircle(
        Offset(size.width * 0.74, size.height * 0.39), 4.8, coinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SplashAuraPainter extends CustomPainter {
  const _SplashAuraPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = 0.82 + (progress * 0.18);
    final center = Offset(size.width * 0.5, size.height * 0.42);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primaryPurple.withValues(alpha: 0.20),
          AppColors.accentPink.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0, 0.44, 1],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.width * 0.74 * pulse),
      );

    canvas.drawCircle(center, size.width * 0.74 * pulse, glowPaint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.18 + i * 0.115);
      canvas.drawLine(
        Offset(size.width * 0.12, y),
        Offset(size.width * 0.88, y + (progress * 6)),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashAuraPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                color: AppColors.accentCoral,
                size: 42,
              ),
              const SizedBox(height: 18),
              Text(
                'Could not start Ortho : Intelligent Finances',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Please try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(132, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
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
            color: const Color(0xFF1E293B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
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
        scale: isSelected ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? null : Colors.transparent,
            gradient: isSelected
                ? const LinearGradient(
                    begin: AlignmentDirectional(-2, 1),
                    end: AlignmentDirectional(1, -1),
                    colors: [
                      Color(0xFF6f2eaf),
                      Color(0xFFFF6B5F),
                    ],
                  )
                : null,
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
