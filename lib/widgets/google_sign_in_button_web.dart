import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

class GoogleSignInWebButton extends StatelessWidget {
  const GoogleSignInWebButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Vazhdo me Google',
      child: Tooltip(
        message: 'Vazhdo me Google',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.clamp(120.0, 400.0);
            return SizedBox(
              height: 54,
              child: Center(
                child: Transform.scale(
                  scaleY: 1.22,
                  child: web.renderButton(
                    configuration: web.GSIButtonConfiguration(
                      type: web.GSIButtonType.standard,
                      theme: web.GSIButtonTheme.outline,
                      size: web.GSIButtonSize.large,
                      text: web.GSIButtonText.continueWith,
                      shape: web.GSIButtonShape.rectangular,
                      logoAlignment: web.GSIButtonLogoAlignment.left,
                      minimumWidth: width,
                      locale: 'sq',
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
