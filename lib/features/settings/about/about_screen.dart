import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About MoneyMate')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MoneyMate', style: AppTypography.headlineLg),
            const SizedBox(height: 4),
            Text('Version 1.0.0', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 24),
            const Text(
              'An offline-first personal finance manager with built-in bill splitting. '
              'No cloud sync, no login, no AI — all your data stays on this device.',
              style: AppTypography.bodyLg,
            ),
            const SizedBox(height: 24),
            Text('Developed by AngelRider', style: AppTypography.titleMd),
          ],
        ),
      ),
    );
  }
}
