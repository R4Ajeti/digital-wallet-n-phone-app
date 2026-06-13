import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/home_palette.dart';
import '../widgets/brand_mark.dart';
import 'settings_screen.dart';
import 'ticket_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.user, super.key});

  final User user;

  double _chatFabBottom(BuildContext context) {
    const bottomBarPadding = 12.0;
    const presentButtonHeight = 50.0;
    const gapAboveButton = 12.0;

    return bottomBarPadding +
        presentButtonHeight +
        bottomBarPadding +
        MediaQuery.viewPaddingOf(context).bottom +
        gapAboveButton;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: HomePalette.systemBar,
        systemNavigationBarColor: HomePalette.systemBar,
        systemNavigationBarDividerColor: HomePalette.systemBar,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: HomePalette.backgroundEdge,
        body: Stack(
          children: [
            // Background Gradient
            const Positioned.fill(child: _HomeBackground()),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.viewPaddingOf(context).top,
              child: const ColoredBox(color: HomePalette.systemBar),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: MediaQuery.viewPaddingOf(context).bottom,
              child: const ColoredBox(color: HomePalette.systemBar),
            ),

            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: _DashboardHeader(user: user),
                  ),

                  // Balance Section
                  const SizedBox(height: 20),
                  const Text(
                    'Në kuletën digjitale ju keni',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '0.00 €',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      width: 304,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HomePalette.topUpButton,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Mbushni kuletën me kartelë bankare',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // White Bottom Card
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            ListView(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                32,
                                16,
                                100,
                              ),
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: _TicketBuyCard(
                                        title: 'Bileta për një drejtim',
                                        price: '0.50 €',
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    const Expanded(
                                      child: _TicketBuyCard(
                                        title: 'Bileta Ditore',
                                        price: '0.80 €',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 29),
                                Row(
                                  children: [
                                    const Expanded(
                                      child: _TicketBuyCard(
                                        title: 'Bileta Mujore e Linjës',
                                        price: '12.00 €',
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    const Expanded(
                                      child: _TicketBuyCard(
                                        title: 'Bileta Mujore e Integruar',
                                        price: '13.50 €',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              right: 16,
              bottom: _chatFabBottom(context),
              child: const _ChatFab(),
            ),

            // Bottom CTA
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.viewPaddingOf(context).bottom,
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.white),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 19),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: HomePalette.presentLeft.withValues(
                            alpha: 0.22,
                          ),
                          blurRadius: 26,
                          offset: const Offset(0, 9),
                        ),
                      ],
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          HomePalette.presentLeft,
                          HomePalette.presentMid,
                          HomePalette.presentRight,
                        ],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TicketScreen(user: user),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Prezanto biletën',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 21,
              child: ColoredBox(color: HomePalette.systemBar),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF6B2D2E),
                Color(0xFF4B2223),
                HomePalette.backgroundEdge,
              ],
              stops: [0.0, 0.34, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [Color(0xB0A13E3F), Color(0x00000000)],
              stops: [0.0, 0.56],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0x85151212), Color(0x00000000)],
              stops: [0.0, 0.50],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatFab extends StatelessWidget {
  const _ChatFab();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {},
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 54,
          height: 54,
          child: Center(child: _ChatFabIcon()),
        ),
      ),
    );
  }
}

class _ChatFabIcon extends StatelessWidget {
  const _ChatFabIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(32, 28), painter: _ChatFabPainter());
  }
}

class _ChatFabPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HomePalette.presentRight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(1.5, 1.5, size.width - 7, size.height - 8),
      const Radius.circular(11),
    );
    final path = Path()..addRRect(bubble);
    path
      ..moveTo(size.width - 8.5, size.height - 8)
      ..quadraticBezierTo(
        size.width - 6.5,
        size.height - 2.5,
        size.width - 1.5,
        size.height - 1.5,
      )
      ..quadraticBezierTo(
        size.width - 7.5,
        size.height - 1.3,
        size.width - 11.5,
        size.height - 5.5,
      );
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = HomePalette.presentRight
      ..style = PaintingStyle.fill;
    for (final x in [10.0, 16.0, 22.0]) {
      canvas.drawCircle(Offset(x, 13.5), 1.65, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.user});

  static const _headerHeight = 48.0;
  static const _headerTextFontSize = 16.0;
  static const _menuButtonSize = 55.2;
  static const _menuIconSize = 36.0;

  final User user;

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
            child: BrandMark(size: 45),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 68),
            child: Text(
              'Komuna e Prishtinës',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: _headerTextFontSize,
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SettingsScreen(user: user),
                  ),
                );
              },
              icon: const Icon(
                Icons.menu_rounded,
                size: _menuIconSize,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketBuyCard extends StatelessWidget {
  const _TicketBuyCard({required this.title, required this.price});

  final String title;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [HomePalette.ticketCardTop, HomePalette.ticketCardBottom],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      height: 170,
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 36,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            price,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: HomePalette.ticketCardButton,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Bleje këtë biletë',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
