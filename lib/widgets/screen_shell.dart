import 'package:flutter/material.dart';

class ScreenShell extends StatelessWidget {
  const ScreenShell({required this.child, this.bottom, super.key});

  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                child: child,
              ),
            ),
            if (bottom != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}
