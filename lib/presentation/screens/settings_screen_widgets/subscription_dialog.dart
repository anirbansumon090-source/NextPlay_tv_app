// lib/presentation/screens/settings_screen_widgets/subscription_dialog.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'settings_shared_widgets.dart';

class SubscriptionDialog extends StatelessWidget {
  const SubscriptionDialog({super.key, required this.plans});
  final List plans;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF131B2E),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Subscription Plan',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 480,
        child: plans.isEmpty
            ? const Text('No plans available.',
                style: TextStyle(color: Colors.white54))
            : ListView.separated(
                shrinkWrap: true,
                itemCount: plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final p = plans[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0F19),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(p.badge,
                                  style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(p.price,
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(p.description,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TvDialogAction(
          label: 'Close',
          autofocus: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
