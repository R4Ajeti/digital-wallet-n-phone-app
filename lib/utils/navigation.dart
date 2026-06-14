import 'package:flutter/widgets.dart';

Future<bool> maybePopRoute(BuildContext context) {
  return Navigator.of(context).maybePop();
}
