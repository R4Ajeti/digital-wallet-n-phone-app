import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  if (kIsWeb) {
    MobileScannerPlatform.instance.setBarcodeLibraryScriptUrl(
      Uri.base.resolve('vendor/zxing.min.js').toString(),
    );
  }

  runApp(const KuletaDigitaleApp());
}
