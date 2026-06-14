import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_session_user.dart';
import '../models/app_user_data.dart';
import '../services/database_service.dart';
import '../services/local_image_service.dart';
import '../theme/home_palette.dart';
import '../utils/messages.dart';
import '../widgets/brand_mark.dart';
import '../widgets/profile_card.dart';
import '../widgets/qr_ticket_widget.dart';
import 'settings_screen.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({
    required this.user,
    this.databaseService,
    this.localImageService,
    super.key,
  });

  final AppSessionUser user;
  final DatabaseService? databaseService;
  final LocalImageService? localImageService;

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  late final DatabaseService _databaseService;
  late final LocalImageService _localImageService;

  late final AppUserData _fallbackData;
  late final Stream<AppUserData> _userStream;
  bool _isNavigatingBack = false;

  @override
  void initState() {
    super.initState();
    _databaseService = widget.databaseService ?? DatabaseService();
    _localImageService = widget.localImageService ?? LocalImageService();
    _fallbackData = AppUserData.demo(
      uid: widget.user.uid,
      email: widget.user.email,
      username: widget.user.displayName,
    );
    _userStream = _databaseService.watchUser(widget.user);
    _ensureData();
  }

  Future<void> _ensureData() async {
    try {
      await _databaseService.ensureUserData(widget.user);
    } catch (_) {
      if (mounted) {
        showAppMessage(
          context,
          'Bileta demo u hap. Sinkronizimi online nuk u përditësua.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlayStyle = SystemUiOverlayStyle.light.copyWith(
      statusBarColor: HomePalette.systemBar,
      systemNavigationBarColor: HomePalette.systemBar,
      systemNavigationBarDividerColor: HomePalette.systemBar,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.light,
    );
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.viewPaddingOf(context).top,
              child: const ColoredBox(color: HomePalette.systemBar),
            ),
            SafeArea(
              child: StreamBuilder<AppUserData>(
                initialData: _fallbackData,
                stream: _userStream,
                builder: (context, snapshot) {
                  final data = snapshot.data ?? _fallbackData;

                  return FutureBuilder<List<Uint8List?>>(
                    future: Future.wait([
                      _localImageService.resolveAvailableBytes(
                        uid: widget.user.profileImageNamespace,
                        kind: LocalImageKind.profile,
                        firebasePath: widget.user.isAnonymous
                            ? ''
                            : data.profileImagePath,
                      ),
                      widget.user.isAnonymous
                          ? Future<Uint8List?>.value()
                          : _localImageService.resolveAvailableBytes(
                              uid: widget.user.uid,
                              kind: LocalImageKind.overlay,
                              firebasePath: data.overlayImagePath,
                            ),
                    ]),
                    builder: (context, localPaths) {
                      final profileBytes = localPaths.data?[0];
                      final overlayBytes = localPaths.data?[1];
                      return _buildContent(
                        data: data,
                        profileBytes: profileBytes,
                        overlayBytes: overlayBytes,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required AppUserData data,
    required Uint8List? profileBytes,
    required Uint8List? overlayBytes,
  }) {
    final qrSize = (MediaQuery.sizeOf(context).width - 32) * 0.68;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HomeHeader(onMenuPressed: _openSettings),
                const SizedBox(height: 30),
                QrTicketWidget(
                  qrValue: data.qrCodeId,
                  overlayImageBytes: overlayBytes,
                  positionX: data.overlayPositionX,
                  positionY: data.overlayPositionY,
                  maxQrSize: qrSize,
                  animateOverlay: !widget.user.isAnonymous,
                  onPositionSaved: (x, y) =>
                      _databaseService.saveOverlayPosition(widget.user, x, y),
                ),
                const SizedBox(height: 12),
                ProfileCard(
                  userTypeLabel: data.userTypeLabel,
                  imageBytes: profileBytes,
                  imageScale: 1.3,
                ),
                const SizedBox(height: 16),
                TicketValidityCard(expirationText: data.expiresAtText),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              key: const Key('ticket-back-button'),
              onPressed: _isNavigatingBack ? null : _goBack,
              icon: const Icon(Icons.chevron_left_rounded, color: _ticketGrey),
              label: const Text(
                'Kthehu',
                style: TextStyle(
                  color: _ticketGrey,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                side: const BorderSide(color: _ticketBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
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

  Future<void> _goBack() async {
    if (_isNavigatingBack) {
      return;
    }
    setState(() => _isNavigatingBack = true);
    final didPop = await Navigator.of(context).maybePop();
    if (!didPop && mounted) {
      setState(() => _isNavigatingBack = false);
      showAppMessage(context, 'Jeni në ekranin kryesor.');
    }
  }
}

const _ticketBlack = Color(0xFF050505);
const _ticketGrey = Color(0xFF9A9A9A);
const _ticketBorder = Color(0xFFD9D9D9);

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onMenuPressed});

  static const _headerHeight = 56.0;
  static const _menuButtonSize = 55.2;
  static const _brandSize = 46.0;
  static const _titleFontSize = 14.0;
  static const _menuIconSize = 40.0;

  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _headerHeight,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: BrandMark(size: _brandSize),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 68),
            child: Text(
              'Komuna e Prishtinës',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ticketBlack,
                fontSize: _titleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Hap menynë',
              style: IconButton.styleFrom(
                fixedSize: const Size.square(_menuButtonSize),
                minimumSize: const Size.square(_menuButtonSize),
                padding: EdgeInsets.zero,
              ),
              onPressed: onMenuPressed,
              icon: const Icon(
                Icons.menu_rounded,
                size: _menuIconSize,
                color: _ticketBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
