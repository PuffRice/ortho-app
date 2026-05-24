import 'package:flutter/material.dart';
import 'dart:ui';

import '../config/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          Positioned(
            top: -360,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 720,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryViolet.withOpacity(0.35),
                      AppColors.primaryDeep.withOpacity(0.0),
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with profile and notification
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // Active Balance Card
                    _buildActiveBalanceCard(),
                    const SizedBox(height: 14),

                    // Inflow and Outflow Cards in Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildFinancialCard(
                            icon: Icons.arrow_downward,
                            iconColor: AppColors.incomePositive,
                            label: 'Inflow this month',
                            amount: '\$6,240.00',
                            change: '+18.7%',
                            changeColor: AppColors.incomePositive,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildFinancialCard(
                            icon: Icons.arrow_upward,
                            iconColor: AppColors.expenseNegative,
                            label: 'Outflow this month',
                            amount: '\$3,860.00',
                            change: '-12.4%',
                            changeColor: AppColors.expenseNegative,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Transaction History Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transaction History',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            'View all',
                            style: TextStyle(
                              color: AppColors.accentCoral,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTransactionItem(
                      name: 'Kristin Watson',
                      time: '09:40 AM',
                      amount: '-\$125.00',
                      category: 'Traveling',
                      avatarText: 'K',
                    ),
                    const SizedBox(height: 12),
                    _buildTransactionItem(
                      name: 'Jane Cooper',
                      time: '10:30 AM',
                      amount: '+\$200.00',
                      category: 'Traveling',
                      avatarText: 'J',
                      isPositive: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTransactionItem(
                      name: 'Wade Warren',
                      time: '11:55 AM',
                      amount: '-\$325.00',
                      category: 'Traveling',
                      avatarText: 'W',
                    ),
                    const SizedBox(height: 12),
                    _buildTransactionItem(
                      name: 'Annette Black',
                      time: '11:20 AM',
                      amount: '+\$280.00',
                      category: 'Traveling',
                      avatarText: 'A',
                      isPositive: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTransactionItem(
                      name: 'Cody Fisher',
                      time: '12:00 PM',
                      amount: '-\$225.00',
                      category: 'Traveling',
                      avatarText: 'C',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header with greeting and notification
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryViolet.withOpacity(0.75),
                  width: 2,
                ),
                color: Colors.transparent,
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Icon(Icons.person, color: AppColors.textPrimary, size: 28),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning 👋',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Leslie Alexander',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.08),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.notifications_none,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  // Active Balance Card
  Widget _buildActiveBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A145A),
            Color(0xFF3B1B7A),
            Color(0xFF20113F),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.25),
            blurRadius: 60,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Active Balance',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: const Icon(
                        Icons.visibility,
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '\$94,765.50',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: AlignmentDirectional(-2,1),
                end:  AlignmentDirectional(1,-1),
                colors: [
                  AppColors.primaryViolet.withValues(alpha: 1),
                  AppColors.accentCoral.withValues(alpha: 1),
                ],
              ),
            ),
            child: const Icon(Icons.wallet, color: AppColors.textPrimary, size: 24),
          ),
        ],
      ),
    );
  }

  // Financial Card (Inflow/Outflow)
  Widget _buildFinancialCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String amount,
    required String change,
    required Color changeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.055),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(0.2),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: changeColor.withOpacity(0.15),
            ),
            child: Text(
              change,
              style: TextStyle(
                color: changeColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Transaction Item
  Widget _buildTransactionItem({
    required String name,
    required String time,
    required String amount,
    required String category,
    required String avatarText,
    bool isPositive = false,
  }) {
    final amountColor = isPositive
      ? AppColors.incomePositive
      : AppColors.expenseNegative;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.055),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
          width: 1,
        ),
      ),
      height: 74,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
            ),
            child: Center(
              child: Text(
                avatarText,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: amountColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                category,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
