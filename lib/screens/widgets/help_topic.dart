import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class HelpTopic extends StatelessWidget {
  const HelpTopic({super.key, required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(answer,
              style:
                  const TextStyle(color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}
