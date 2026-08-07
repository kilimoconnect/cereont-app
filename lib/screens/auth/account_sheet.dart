import 'package:flutter/material.dart';

import '../../config/supabase_config.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

/// Bottom sheet showing the signed-in account with a sign-out action.
class AccountSheet extends StatelessWidget {
  const AccountSheet({super.key});

  static void show(BuildContext context) {
    if (!SupabaseConfig.isConfigured) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => const AccountSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final name = auth.displayName;
    final email = auth.currentUser?.email ?? '';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InitialsAvatar(name, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      if (email.isNotEmpty)
                        Text(email,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE5484D),
                  side: const BorderSide(color: Color(0x55E5484D)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onPressed: () async {
                  await AuthService.instance.signOut();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
