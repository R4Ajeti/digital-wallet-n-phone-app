import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../models/app_user_data.dart';
import '../services/database_service.dart';
import '../services/local_image_service.dart';
import '../utils/messages.dart';
import '../widgets/brand_mark.dart';
import '../widgets/profile_card.dart';
import '../widgets/qr_ticket_widget.dart';
import 'settings_screen.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({required this.user, super.key});

  final User user;

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final _databaseService = DatabaseService();
  final _localImageService = LocalImageService();

  late final Stream<AppUserData> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = _databaseService.watchUser(widget.user.uid);
    _ensureData();
  }

  Future<void> _ensureData() async {
    try {
      await _databaseService.ensureUserData(widget.user);
    } catch (_) {
      if (mounted) {
        showAppMessage(
          context,
          'Të dhënat nuk u përditësuan. Kontrollo internetin.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<AppUserData>(
          stream: _userStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorState(onRetry: _ensureData);
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!;
            return FutureBuilder<List<String>>(
              future: Future.wait([
                _localImageService.resolveAvailablePath(
                  uid: widget.user.uid,
                  kind: LocalImageKind.profile,
                  firebasePath: data.profileImagePath,
                ),
                _localImageService.resolveAvailablePath(
                  uid: widget.user.uid,
                  kind: LocalImageKind.overlay,
                  firebasePath: data.overlayImagePath,
                ),
              ]),
              builder: (context, localPaths) {
                final profilePath = localPaths.data?[0] ?? '';
                final overlayPath = localPaths.data?[1] ?? '';
                return _buildContent(
                  data: data,
                  profilePath: profilePath,
                  overlayPath: overlayPath,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent({
    required AppUserData data,
    required String profilePath,
    required String overlayPath,
  }) {
    final qrSize = (MediaQuery.sizeOf(context).width - 36) * 0.7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HomeHeader(onMenuPressed: _openSettings),
                const SizedBox(height: 24),
                QrTicketWidget(
                  qrValue: data.activeQrValue,
                  overlayImagePath: overlayPath,
                  positionX: data.overlayPositionX,
                  positionY: data.overlayPositionY,
                  maxQrSize: qrSize,
                  animateOverlay: true,
                  onPositionSaved: (x, y) => _databaseService
                      .saveOverlayPosition(widget.user.uid, x, y),
                ),
                const SizedBox(height: 20),
                ProfileCard(
                  userTypeLabel: data.userTypeLabel,
                  imagePath: profilePath,
                ),
                const SizedBox(height: 16),
                TicketValidityCard(expirationText: data.expiresAtText),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: OutlinedButton.icon(
            onPressed: _goBack,
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.muted,
            ),
            label: const Text(
              'Kthehu',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(user: widget.user),
      ),
    );
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    showAppMessage(context, 'Jeni në ekranin kryesor.');
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onMenuPressed});

  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: BrandMark(size: 42),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 60),
            child: Text(
              'Komuna e Prishtinës',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Hap menynë',
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu_rounded, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.primary,
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(
              'Të dhënat nuk u ngarkuan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Kontrollo internetin dhe provo përsëri.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Provo përsëri'),
            ),
          ],
        ),
      ),
    );
  }
}
