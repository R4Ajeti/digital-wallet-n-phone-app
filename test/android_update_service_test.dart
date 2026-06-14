import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kuletadigitalen/services/android_update_service.dart';

void main() {
  test(
    'detects a newer semantic version and selects the Android APK',
    () async {
      final service = AndroidUpdateService(
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'tag_name': 'v1.2.0',
              'html_url': 'https://github.com/example/releases/tag/v1.2.0',
              'assets': [
                {
                  'name': 'kuleta-digitale-n-app-v1.2.0-android.apk',
                  'browser_download_url':
                      'https://github.com/example/releases/download/app.apk',
                },
              ],
            }),
            200,
          );
        }),
      );

      final result = await service.check(installedVersion: '1.1.9');

      expect(result.status, AndroidUpdateStatus.updateAvailable);
      expect(result.update!.version.toString(), '1.2.0');
      expect(result.update!.apkUri, isNotNull);
    },
  );

  test('reports up to date when the release is not newer', () async {
    final service = AndroidUpdateService(
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'tag_name': 'v1.0.1',
            'html_url': 'https://github.com/example/releases/tag/v1.0.1',
            'assets': const [],
          }),
          200,
        );
      }),
    );

    final result = await service.check(installedVersion: '1.0.1');

    expect(result.status, AndroidUpdateStatus.upToDate);
  });

  test(
    'falls back to the release page when the APK asset is missing',
    () async {
      final service = AndroidUpdateService(
        client: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'tag_name': 'v2.0.0',
              'html_url': 'https://github.com/example/releases/tag/v2.0.0',
              'assets': [
                {
                  'name': 'notes.txt',
                  'browser_download_url':
                      'https://github.com/example/releases/download/notes.txt',
                },
              ],
            }),
            200,
          );
        }),
      );

      final result = await service.check(installedVersion: '1.0.0');

      expect(result.status, AndroidUpdateStatus.updateAvailable);
      expect(result.update!.apkUri, isNull);
      expect(result.update!.downloadUri, result.update!.releaseUri);
    },
  );

  test('network and invalid release responses never throw', () async {
    final networkFailure = AndroidUpdateService(
      client: MockClient((_) => throw Exception('offline')),
    );
    final invalidRelease = AndroidUpdateService(
      client: MockClient((_) async => http.Response('{}', 200)),
    );

    expect(
      (await networkFailure.check(installedVersion: '1.0.0')).status,
      AndroidUpdateStatus.unavailable,
    );
    expect(
      (await invalidRelease.check(installedVersion: '1.0.0')).status,
      AndroidUpdateStatus.unavailable,
    );
  });
}
