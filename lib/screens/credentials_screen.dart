import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_colors.dart';
import '../cqrs/commands.dart';
import '../cqrs/queries.dart';
import '../models/isar_models.dart';
import '../services/cqrs_service.dart';
import '../services/user_identity.dart';

class CredentialsScreen extends StatefulWidget {
  const CredentialsScreen({super.key});

  @override
  State<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen> {
  Future<_CredentialsData>? _credentialsFuture;

  Future<_CredentialsData> get _credentialsData {
    return _credentialsFuture ??= _loadCredentials();
  }

  @override
  void initState() {
    super.initState();
    _credentialsFuture = _loadCredentials();
  }

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
                      AppColors.primaryDeep.withOpacity(0),
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: FutureBuilder<_CredentialsData>(
              future: _credentialsData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _buildLoadError();
                }
                return _buildContent(snapshot.data!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: TextButton(
        onPressed: _reload,
        child: const Text('Retry credentials'),
      ),
    );
  }

  Widget _buildContent(_CredentialsData data) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            title: 'Cards',
            actionLabel: 'Add card',
            onTap: () => _showCardSheet(data),
          ),
          const SizedBox(height: 14),
          data.cards.isEmpty
              ? _buildEmptyPanel('No cards saved yet.')
              : _buildCardStack(data),
          const SizedBox(height: 32),
          _buildSectionHeader(
            title: 'Bank accounts',
            actionLabel: 'Add bank',
            onTap: () => _showBankSheet(data),
          ),
          const SizedBox(height: 14),
          if (data.banks.isEmpty)
            _buildEmptyPanel('No bank account credentials saved yet.')
          else
            for (final bank in data.banks) ...[
              _buildBankBlock(bank, data),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Credentials',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Cards and bank details in one secure place',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _reload,
          icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add, size: 18),
          label: Text(actionLabel),
          style: TextButton.styleFrom(foregroundColor: AppColors.accentCoral),
        ),
      ],
    );
  }

  Widget _buildCardStack(_CredentialsData data) {
    final cards = data.cards.take(4).toList();
    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var index = cards.length - 1; index >= 0; index--)
            Positioned(
              top: 22.0 * index,
              left: 18.0 * index,
              right: 18.0 * index,
              child: Transform.rotate(
                angle: (index - 1) * 0.035,
                child: _buildPaymentCard(cards[index], data),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
    PaymentCardCredentialEntity card,
    _CredentialsData data,
  ) {
    return GestureDetector(
      onTap: () => _showCardSheet(data, initial: card),
      onLongPress: () => _confirmDeleteCard(data, card),
      child: Container(
        height: 190,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _cardGradient(card.network),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDeep.withOpacity(0.30),
              blurRadius: 36,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Row(
                children: [
                  _buildLogo(card.bankLogoBase64, 42),
                  const SizedBox(width: 10),
                  Text(
                    card.bankName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: _buildPill(card.cardType.toUpperCase()),
            ),
            Positioned(
              top: 68,
              left: 0,
              child: _buildChip(),
            ),
            if (card.hasNfc)
              const Positioned(
                top: 72,
                left: 56,
                child: Icon(
                  Icons.contactless,
                  color: AppColors.textPrimary,
                  size: 26,
                ),
              ),
            Positioned(
              left: 0,
              bottom: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _maskedCardNumber(card.cardNumber),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.cardholderName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Text(
                _networkLabel(card.network),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankBlock(
    BankAccountCredentialEntity bank,
    _CredentialsData data,
  ) {
    return InkWell(
      onTap: () => _showBankSheet(data, initial: bank),
      onLongPress: () => _confirmDeleteBank(data, bank),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _surfaceDecoration(radius: 22),
        child: Column(
          children: [
            Row(
              children: [
                _buildLogo(bank.bankLogoBase64, 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank.bankName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bank.branchName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showBankSheet(data, initial: bank),
                  icon: const Icon(Icons.edit, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildCopyRow('ACC no', bank.accountNumber),
            _buildCopyRow('Acc Name', bank.accountName),
            _buildCopyRow('Routing No', bank.routingNumber),
            _buildCopyRow('Swift Code', bank.swiftCode),
            _buildCopyRow('Bank Name', bank.bankName),
            _buildCopyRow('Branch Name', bank.branchName),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _copy(value, label),
            icon: const Icon(Icons.copy, color: AppColors.textSecondary),
            iconSize: 18,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(String? logoBase64, double size) {
    final bytes = _decodeLogo(logoBase64);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes == null
          ? const Icon(Icons.account_balance, color: AppColors.textSecondary)
          : Image.memory(bytes, fit: BoxFit.cover),
    );
  }

  Widget _buildChip() {
    return Container(
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFFFC66B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(painter: _ChipPainter()),
    );
  }

  Widget _buildPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEmptyPanel(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(radius: 22),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _showCardSheet(
    _CredentialsData data, {
    PaymentCardCredentialEntity? initial,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return _CardCredentialSheet(data: data, initial: initial);
      },
    );
    if (saved == true && mounted) {
      _reload();
    }
  }

  Future<void> _showBankSheet(
    _CredentialsData data, {
    BankAccountCredentialEntity? initial,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return _BankCredentialSheet(data: data, initial: initial);
      },
    );
    if (saved == true && mounted) {
      _reload();
    }
  }

  Future<void> _confirmDeleteCard(
    _CredentialsData data,
    PaymentCardCredentialEntity card,
  ) async {
    final confirmed = await _confirmDelete('Delete this card?');
    if (confirmed != true) {
      return;
    }
    await data.cqrs.bus.execute(
      DeletePaymentCardCredentialCommand(
        userId: data.profile.userId,
        cardCredentialId: card.cardCredentialId,
      ),
    );
    _reload();
  }

  Future<void> _confirmDeleteBank(
    _CredentialsData data,
    BankAccountCredentialEntity bank,
  ) async {
    final confirmed = await _confirmDelete('Delete this bank account?');
    if (confirmed != true) {
      return;
    }
    await data.cqrs.bus.execute(
      DeleteBankAccountCredentialCommand(
        userId: data.profile.userId,
        bankCredentialId: bank.bankCredentialId,
      ),
    );
    _reload();
  }

  Future<bool?> _confirmDelete(String title) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: const Text(
            'This will remove it locally and sync the deletion.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<_CredentialsData> _loadCredentials() async {
    final profile = await UserIdentityService.instance.getProfile();
    final cqrs = await CqrsService.create();
    final cards = await cqrs.bus.query<GetPaymentCardCredentialsQuery,
        List<PaymentCardCredentialEntity>>(
      GetPaymentCardCredentialsQuery(userId: profile.userId),
    );
    final banks = await cqrs.bus.query<GetBankAccountCredentialsQuery,
        List<BankAccountCredentialEntity>>(
      GetBankAccountCredentialsQuery(userId: profile.userId),
    );
    return _CredentialsData(
      profile: profile,
      cqrs: cqrs,
      cards: cards,
      banks: banks,
    );
  }

  Future<void> _reload() async {
    final next = _loadCredentials();
    setState(() {
      _credentialsFuture = next;
    });
    await next;
  }

  Future<void> _copy(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
  }

  BoxDecoration _surfaceDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    );
  }

  List<Color> _cardGradient(String network) {
    if (network == 'visa') {
      return const [Color(0xFF2A145A), Color(0xFF3B1B7A), Color(0xFF20113F)];
    }
    if (network == 'mastercard') {
      return const [Color(0xFF3A1428), Color(0xFF70255B), Color(0xFF26113F)];
    }
    return const [Color(0xFF171A2E), Color(0xFF39276D), Color(0xFF111427)];
  }

  String _networkLabel(String network) {
    if (network == 'visa') {
      return 'VISA';
    }
    if (network == 'mastercard') {
      return 'Mastercard';
    }
    return network.toUpperCase();
  }

  String _maskedCardNumber(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    final lastFour = digits.length <= 4
        ? digits.padLeft(4, '*')
        : digits.substring(digits.length - 4);
    return '****  ****  ****  $lastFour';
  }
}

class _CardCredentialSheet extends StatefulWidget {
  const _CardCredentialSheet({required this.data, this.initial});

  final _CredentialsData data;
  final PaymentCardCredentialEntity? initial;

  @override
  State<_CardCredentialSheet> createState() => _CardCredentialSheetState();
}

class _CardCredentialSheetState extends State<_CardCredentialSheet> {
  final _bankController = TextEditingController();
  final _holderController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  String _cardType = 'debit';
  String _network = 'visa';
  bool _hasNfc = true;
  String? _logoBase64;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _bankController.text = initial.bankName;
      _holderController.text = initial.cardholderName;
      _numberController.text = initial.cardNumber;
      _expiryController.text = initial.expiry;
      _cardType = initial.cardType;
      _network = initial.network;
      _hasNfc = initial.hasNfc;
      _logoBase64 = initial.bankLogoBase64;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: widget.initial == null ? 'Add card' : 'Edit card',
      saving: _saving,
      actionLabel: widget.initial == null ? 'Save card' : 'Update card',
      onSave: _save,
      children: [
        _LogoPicker(logoBase64: _logoBase64, onPicked: _pickLogo),
        _SheetField(controller: _bankController, label: 'Bank name'),
        _SheetField(controller: _holderController, label: 'Cardholder name'),
        _SheetField(
          controller: _numberController,
          label: 'Card number',
          keyboardType: TextInputType.number,
        ),
        _SheetField(controller: _expiryController, label: 'Expiry (MM/YY)'),
        _SheetDropdown(
          label: 'Card type',
          value: _cardType,
          values: const ['debit', 'credit', 'prepaid'],
          onChanged: (value) => setState(() => _cardType = value),
        ),
        _SheetDropdown(
          label: 'Network',
          value: _network,
          values: const ['visa', 'mastercard', 'other'],
          onChanged: (value) => setState(() => _network = value),
        ),
        SwitchListTile(
          value: _hasNfc,
          onChanged: (value) => setState(() => _hasNfc = value),
          title:
              const Text('NFC enabled', style: TextStyle(color: Colors.white)),
          activeThumbColor: AppColors.primaryViolet,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return;
    }
    final bytes = await picked.readAsBytes();
    setState(() {
      _logoBase64 = base64Encode(bytes);
    });
  }

  Future<void> _save() async {
    if (_bankController.text.trim().isEmpty ||
        _holderController.text.trim().isEmpty ||
        _numberController.text.trim().isEmpty ||
        _expiryController.text.trim().isEmpty) {
      _showSheetError(context, 'Fill all required card details.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.data.cqrs.bus.execute(
        UpsertPaymentCardCredentialCommand(
          userId: widget.data.profile.userId,
          cardCredentialId: widget.initial?.cardCredentialId,
          bankName: _bankController.text.trim(),
          bankLogoBase64: _logoBase64,
          cardType: _cardType,
          network: _network,
          cardholderName: _holderController.text.trim(),
          cardNumber: _numberController.text.trim(),
          expiry: _expiryController.text.trim(),
          hasNfc: _hasNfc,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      _showSheetError(context, 'Unable to save card: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _bankController.dispose();
    _holderController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    super.dispose();
  }
}

class _BankCredentialSheet extends StatefulWidget {
  const _BankCredentialSheet({required this.data, this.initial});

  final _CredentialsData data;
  final BankAccountCredentialEntity? initial;

  @override
  State<_BankCredentialSheet> createState() => _BankCredentialSheetState();
}

class _BankCredentialSheetState extends State<_BankCredentialSheet> {
  final _bankController = TextEditingController();
  final _branchController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _routingController = TextEditingController();
  final _swiftController = TextEditingController();
  String? _logoBase64;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _bankController.text = initial.bankName;
      _branchController.text = initial.branchName;
      _accountNameController.text = initial.accountName;
      _accountNumberController.text = initial.accountNumber;
      _routingController.text = initial.routingNumber;
      _swiftController.text = initial.swiftCode;
      _logoBase64 = initial.bankLogoBase64;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: widget.initial == null ? 'Add bank account' : 'Edit bank account',
      saving: _saving,
      actionLabel: widget.initial == null ? 'Save bank' : 'Update bank',
      onSave: _save,
      children: [
        _LogoPicker(logoBase64: _logoBase64, onPicked: _pickLogo),
        _SheetField(controller: _bankController, label: 'Bank name'),
        _SheetField(controller: _branchController, label: 'Branch name'),
        _SheetField(controller: _accountNameController, label: 'Account name'),
        _SheetField(
          controller: _accountNumberController,
          label: 'Account number',
          keyboardType: TextInputType.number,
        ),
        _SheetField(controller: _routingController, label: 'Routing number'),
        _SheetField(controller: _swiftController, label: 'Swift code'),
      ],
    );
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return;
    }
    final bytes = await picked.readAsBytes();
    setState(() {
      _logoBase64 = base64Encode(bytes);
    });
  }

  Future<void> _save() async {
    final required = [
      _bankController,
      _branchController,
      _accountNameController,
      _accountNumberController,
      _routingController,
      _swiftController,
    ];
    if (required.any((controller) => controller.text.trim().isEmpty)) {
      _showSheetError(context, 'Fill all bank account details.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.data.cqrs.bus.execute(
        UpsertBankAccountCredentialCommand(
          userId: widget.data.profile.userId,
          bankCredentialId: widget.initial?.bankCredentialId,
          bankName: _bankController.text.trim(),
          bankLogoBase64: _logoBase64,
          branchName: _branchController.text.trim(),
          accountName: _accountNameController.text.trim(),
          accountNumber: _accountNumberController.text.trim(),
          routingNumber: _routingController.text.trim(),
          swiftCode: _swiftController.text.trim(),
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      _showSheetError(context, 'Unable to save bank account: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _bankController.dispose();
    _branchController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _routingController.dispose();
    _swiftController.dispose();
    super.dispose();
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.title,
    required this.children,
    required this.saving,
    required this.actionLabel,
    required this.onSave,
  });

  final String title;
  final List<Widget> children;
  final bool saving;
  final String actionLabel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            for (final child in children) ...[
              child,
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: saving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryViolet,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryViolet),
        ),
      ),
    );
  }
}

class _SheetDropdown extends StatelessWidget {
  const _SheetDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: values
          .map(
            (value) => DropdownMenuItem(
              value: value,
              child: Text(value.toUpperCase()),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      dropdownColor: AppColors.bgSecondary,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryViolet),
        ),
      ),
    );
  }
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({required this.logoBase64, required this.onPicked});

  final String? logoBase64;
  final VoidCallback onPicked;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeLogo(logoBase64);
    return InkWell(
      onTap: onPicked,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: bytes == null
                  ? const Icon(
                      Icons.add_photo_alternate,
                      color: AppColors.textSecondary,
                    )
                  : Image.memory(bytes, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Bank logo',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _CredentialsData {
  const _CredentialsData({
    required this.profile,
    required this.cqrs,
    required this.cards,
    required this.banks,
  });

  final UserIdentityProfile profile;
  final CqrsService cqrs;
  final List<PaymentCardCredentialEntity> cards;
  final List<BankAccountCredentialEntity> banks;
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.5, 0),
      Offset(size.width * 0.5, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.48),
      Offset(size.width, size.height * 0.48),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(7, 7, size.width - 14, size.height - 14),
        const Radius.circular(5),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Uint8List? _decodeLogo(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  try {
    return base64Decode(value);
  } catch (_) {
    return null;
  }
}

void _showSheetError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
