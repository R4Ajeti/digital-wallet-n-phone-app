import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/android_update_service.dart';
import '../utils/messages.dart';

class AndroidUpdateChecker extends StatefulWidget {
  const AndroidUpdateChecker({required this.child, super.key});

  final Widget child;

  @override
  State<AndroidUpdateChecker> createState() => _AndroidUpdateCheckerState();
}

class _AndroidUpdateCheckerState extends State<AndroidUpdateChecker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForAndroidUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<void> checkForAndroidUpdate(
  BuildContext context, {
  bool showStatus = false,
  AndroidUpdateService? service,
}) async {
  if (!isAndroidUpdateSupported) {
    if (showStatus && context.mounted) {
      showAppMessage(
        context,
        'Kontrolli i APK-së është i disponueshëm vetëm në Android.',
      );
    }
    return;
  }

  final result = await (service ?? AndroidUpdateService()).check();
  if (!context.mounted) {
    return;
  }

  if (result.status == AndroidUpdateStatus.unavailable) {
    if (showStatus) {
      showAppMessage(
        context,
        'Përditësimet nuk mund të kontrollohen tani. Provo përsëri më vonë.',
        isError: true,
      );
    }
    return;
  }

  if (result.status == AndroidUpdateStatus.upToDate) {
    if (showStatus) {
      showAppMessage(context, 'E ke versionin më të fundit të aplikacionit.');
    }
    return;
  }

  final update = result.update!;
  final shouldOpen = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Version i ri i disponueshëm'),
      content: Text(
        'Versioni ${update.version} i Kuletës Digjitale është gati. '
        'Shkarkimi hapet jashtë aplikacionit dhe Android do të kërkojë '
        'konfirmimin tënd para instalimit.'
        '${update.apkUri == null ? '\n\nAPK-ja nuk u gjet në publikim, '
                  'prandaj do të hapet faqja e publikimit.' : ''}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Më vonë'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(update.apkUri == null ? 'Hap publikimin' : 'Përditëso'),
        ),
      ],
    ),
  );

  if (shouldOpen != true || !context.mounted) {
    return;
  }

  final opened = await launchUrl(
    update.downloadUri,
    mode: LaunchMode.externalApplication,
  );
  if (!opened && context.mounted) {
    showAppMessage(
      context,
      'Lidhja e përditësimit nuk mund të hapej.',
      isError: true,
    );
  }
}
