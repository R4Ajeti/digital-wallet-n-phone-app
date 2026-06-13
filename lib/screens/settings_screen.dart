import 'package:flutter/material.dart';

import '../app.dart';
import '../models/app_session_user.dart';
import '../services/auth_service.dart';
import '../utils/messages.dart';
import '../widgets/brand_mark.dart';
import '../widgets/screen_shell.dart';
import 'change_password_screen.dart';
import 'balance_settings_screen.dart';
import 'profile_image_screen.dart';
import 'qr_overlay_icon_screen.dart';
import 'qr_settings_screen.dart';
import 'ticket_expiration_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.user, super.key});

  final AppSessionUser user;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(
              title: 'Menyja',
              subtitle: 'Menaxho kuletën tënde demo',
              showBack: true,
            ),
            const SizedBox(height: 28),
            _MenuTile(
              icon: Icons.qr_code_2_rounded,
              title: 'Cilësimet e QR Kodit',
              onTap: () => _open(QrSettingsScreen(user: widget.user)),
            ),
            _MenuTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Ndrysho bilancin',
              onTap: () => _open(BalanceSettingsScreen(user: widget.user)),
            ),
            _MenuTile(
              icon: Icons.event_available_rounded,
              title: 'Ndrysho vlefshmërinë e biletës',
              onTap: () => _open(TicketExpirationScreen(user: widget.user)),
            ),
            _MenuTile(
              icon: Icons.account_circle_outlined,
              title: 'Ndrysho fotografinë',
              onTap: () => _open(ProfileImageScreen(user: widget.user)),
            ),
            _MenuTile(
              icon: Icons.layers_outlined,
              title: 'Ndrysho ikonën e QR Kodit',
              onTap: () => _open(QrOverlayIconScreen(user: widget.user)),
            ),
            _MenuTile(
              icon: Icons.password_rounded,
              title: 'Ndrysho fjalëkalimin',
              onTap: () => _open(const ChangePasswordScreen()),
            ),
            _MenuTile(
              icon: Icons.logout_rounded,
              title: _isLoggingOut ? 'Duke dalë…' : 'Dil nga aplikacioni',
              color: AppColors.danger,
              onTap: _isLoggingOut ? null : _confirmLogout,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(Widget screen) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dil nga aplikacioni?'),
        content: const Text(
          'Do të duhet të kyçesh përsëri për ta hapur kuletën.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anulo'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Dil'),
          ),
        ],
      ),
    );
    if (shouldLogout != true) {
      return;
    }

    setState(() => _isLoggingOut = true);
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoggingOut = false);
        showAppMessage(context, 'Dalja dështoi. Provo përsëri.', isError: true);
      }
    }
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color == AppColors.danger
                          ? AppColors.danger
                          : AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
