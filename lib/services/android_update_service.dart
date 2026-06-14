import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

const _latestReleaseUrl =
    'https://api.github.com/repos/R4Ajeti/'
    'digital-wallet-n-phone-app/releases/latest';

bool get isAndroidUpdateSupported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

enum AndroidUpdateStatus { upToDate, updateAvailable, unavailable }

class AndroidUpdateInfo {
  const AndroidUpdateInfo({
    required this.version,
    required this.releaseUri,
    required this.apkUri,
  });

  final Version version;
  final Uri releaseUri;
  final Uri? apkUri;

  Uri get downloadUri => apkUri ?? releaseUri;
}

class AndroidUpdateCheck {
  const AndroidUpdateCheck._(this.status, [this.update]);

  const AndroidUpdateCheck.upToDate() : this._(AndroidUpdateStatus.upToDate);

  const AndroidUpdateCheck.unavailable()
    : this._(AndroidUpdateStatus.unavailable);

  const AndroidUpdateCheck.updateAvailable(AndroidUpdateInfo update)
    : this._(AndroidUpdateStatus.updateAvailable, update);

  final AndroidUpdateStatus status;
  final AndroidUpdateInfo? update;
}

class AndroidUpdateService {
  AndroidUpdateService({
    http.Client? client,
    Uri? latestReleaseUri,
    Future<String> Function()? installedVersionLoader,
  }) : _client = client ?? http.Client(),
       _latestReleaseUri = latestReleaseUri ?? Uri.parse(_latestReleaseUrl),
       _installedVersionLoader =
           installedVersionLoader ?? _loadInstalledVersion;

  final http.Client _client;
  final Uri _latestReleaseUri;
  final Future<String> Function() _installedVersionLoader;

  Future<AndroidUpdateCheck> check({String? installedVersion}) async {
    try {
      final currentVersion = Version.parse(
        _normalizeVersion(installedVersion ?? await _installedVersionLoader()),
      );
      final response = await _client
          .get(
            _latestReleaseUri,
            headers: const {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'kuleta-digitale-android',
              'X-GitHub-Api-Version': '2022-11-28',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return const AndroidUpdateCheck.unavailable();
      }

      final release = jsonDecode(response.body);
      if (release is! Map<String, dynamic>) {
        return const AndroidUpdateCheck.unavailable();
      }

      final tag = release['tag_name'];
      final releaseUrl = release['html_url'];
      if (tag is! String || releaseUrl is! String) {
        return const AndroidUpdateCheck.unavailable();
      }

      final latestVersion = Version.parse(_normalizeVersion(tag));
      if (latestVersion <= currentVersion) {
        return const AndroidUpdateCheck.upToDate();
      }

      final releaseUri = Uri.tryParse(releaseUrl);
      if (releaseUri == null) {
        return const AndroidUpdateCheck.unavailable();
      }

      return AndroidUpdateCheck.updateAvailable(
        AndroidUpdateInfo(
          version: latestVersion,
          releaseUri: releaseUri,
          apkUri: _findAndroidApk(release['assets']),
        ),
      );
    } on Object {
      return const AndroidUpdateCheck.unavailable();
    }
  }

  static Future<String> _loadInstalledVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  static String _normalizeVersion(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('v') || trimmed.startsWith('V')) {
      return trimmed.substring(1);
    }
    return trimmed;
  }

  static Uri? _findAndroidApk(Object? rawAssets) {
    if (rawAssets is! List) {
      return null;
    }

    for (final rawAsset in rawAssets) {
      if (rawAsset is! Map<String, dynamic>) {
        continue;
      }
      final name = rawAsset['name'];
      final downloadUrl = rawAsset['browser_download_url'];
      if (name is String &&
          downloadUrl is String &&
          name.toLowerCase().endsWith('-android.apk')) {
        return Uri.tryParse(downloadUrl);
      }
    }
    return null;
  }
}
