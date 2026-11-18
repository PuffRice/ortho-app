import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class ReceiptViewer extends StatelessWidget {
  const ReceiptViewer({super.key, required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bgPrimary,
    appBar: AppBar(title: const Text('Receipt'), backgroundColor: AppColors.bgSecondary),
    body: Center(child: InteractiveViewer(minScale: 0.5, maxScale: 5,
      child: Image.memory(bytes, errorBuilder: (_, __, ___) =>
        const Text('Could not display this receipt.', style: TextStyle(color: AppColors.textSecondary))))),
  );
}
