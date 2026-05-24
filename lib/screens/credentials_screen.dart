import 'package:flutter/material.dart';

import '../config/app_colors.dart';

class CredentialsScreen extends StatefulWidget {
  const CredentialsScreen({super.key});

  @override
  State<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen> {
  // Card Details Controllers
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardholderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  // Bank Details Controllers
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _routingNumberController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();

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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Header
                Text(
                  'Credentials',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your card and bank details',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // Card Details Section
                _buildSectionTitle('Card Details'),
                const SizedBox(height: 12),
                _buildInputField(
                  controller: _cardNumberController,
                  label: 'Card Number',
                  hint: '1234 5678 9012 3456',
                  icon: Icons.credit_card,
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  controller: _cardholderController,
                  label: 'Cardholder Name',
                  hint: 'John Doe',
                  icon: Icons.person,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildInputField(
                        controller: _expiryController,
                        label: 'Expiry Date',
                        hint: 'MM/YY',
                        icon: Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: _cvvController,
                        label: 'CVV',
                        hint: '123',
                        icon: Icons.lock,
                        isPassword: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Bank Details Section
                _buildSectionTitle('Bank Details'),
                const SizedBox(height: 12),
                _buildInputField(
                  controller: _bankNameController,
                  label: 'Bank Name',
                  hint: 'First National Bank',
                  icon: Icons.business,
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  controller: _accountNumberController,
                  label: 'Account Number',
                  hint: '123456789012',
                  icon: Icons.numbers,
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  controller: _routingNumberController,
                  label: 'Routing Number',
                  hint: '021000021',
                  icon: Icons.route,
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  controller: _accountHolderController,
                  label: 'Account Holder Name',
                  hint: 'John Doe',
                  icon: Icons.person,
                ),
                const SizedBox(height: 28),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        'Clear',
                        onTap: _clearAllFields,
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        'Save',
                        onTap: _saveCredentials,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 100), // Space for floating navbar
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textMuted.withOpacity(0.7),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.textMuted.withOpacity(0.7),
              size: 18,
            ),
            filled: true,
            fillColor: AppColors.bgCard.withOpacity(0.6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primaryViolet.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label, {
    required VoidCallback onTap,
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : AppColors.primaryViolet,
          border: Border.all(
            color: isOutlined
                ? AppColors.primaryViolet.withOpacity(0.6)
                : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isOutlined ? AppColors.primaryViolet : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _clearAllFields() {
    _cardNumberController.clear();
    _cardholderController.clear();
    _expiryController.clear();
    _cvvController.clear();
    _accountNumberController.clear();
    _routingNumberController.clear();
    _bankNameController.clear();
    _accountHolderController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All fields cleared'),
        backgroundColor: Colors.orange.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveCredentials() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Credentials saved securely'),
        backgroundColor: const Color(0xFF4EDEA3),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardholderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    _bankNameController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }
}
