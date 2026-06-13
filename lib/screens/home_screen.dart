import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/home_palette.dart';
import '../widgets/brand_mark.dart';
import 'settings_screen.dart';
import 'ticket_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.user, super.key});

  final User user;

  double _chatFabBottom(BuildContext context) {
    const bottomBarPadding = 12.0;
    const presentButtonHeight = 56.0;
    const gapAboveButton = 14.0;

    return bottomBarPadding +
        presentButtonHeight +
        bottomBarPadding +
        MediaQuery.paddingOf(context).bottom +
        gapAboveButton;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomePalette.backgroundEdge,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.35),
                  radius: 1.15,
                  colors: const [
                    HomePalette.backgroundCenter,
                    HomePalette.backgroundMid,
                    HomePalette.backgroundEdge,
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: _DashboardHeader(user: user),
                ),

                // Balance Section
                const SizedBox(height: 24),
                const Text(
                  'Në kuletën digjitale ju keni',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  '0.00 €',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HomePalette.topUpButton,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Mbushni kuletën me kartelë bankare',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // White Bottom Card
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: Stack(
                        children: [
                          ListView(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _TicketBuyCard(
                                      title: 'Bileta për një drejtim',
                                      price: '0.50 €',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _TicketBuyCard(
                                      title: 'Bileta Ditore',
                                      price: '0.80 €',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _TicketBuyCard(
                                      title: 'Bileta Mujore e Linjës',
                                      price: '12.00 €',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
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
            bottom: 0,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
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
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Prezanto biletën',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatFab extends StatelessWidget {
  const _ChatFab();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: CircleBorder(
        side: BorderSide(
          color: HomePalette.presentLeft.withValues(alpha: 0.35),
        ),
      ),
      child: InkWell(
        onTap: () {},
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 52,
          height: 52,
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
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            color: HomePalette.presentLeft,
            size: 28,
          ),
          Positioned(
            bottom: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(),
                const SizedBox(width: 2.5),
                _dot(),
                const SizedBox(width: 2.5),
                _dot(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: HomePalette.presentLeft,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.user});

  final User user;

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
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Hap menynë',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SettingsScreen(user: user),
                  ),
                );
              },
              icon: const Icon(
                Icons.menu_rounded,
                size: 28,
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
        color: HomePalette.ticketCard,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Text(
            price,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: HomePalette.ticketCardButton,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Bleje këtë biletë'),
            ),
          ),
        ],
      ),
    );
  }
}
