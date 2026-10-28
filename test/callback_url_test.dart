import 'package:fasten_stitch_element_flutter/src/callback_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inferFastenApiOrigin', () {
    test('infers the production API origin from the default embed URL', () {
      expect(
        inferFastenApiOrigin('https://embed.connect.fastenhealth.com/'),
        Uri.parse('https://api.connect.fastenhealth.com/'),
      );
    });

    test('infers the development API origin from an embed override', () {
      expect(
        inferFastenApiOrigin(
          'https://embed.connect.fastenlabs.com/widget?existing=true#section',
        ),
        Uri.parse('https://api.connect.fastenlabs.com/'),
      );
    });

    test('removes query and fragment components, including empty ones', () {
      for (final suffix in [
        '?existing=true',
        '#section',
        '?existing=true#section',
        '?',
        '#',
        '?#',
      ]) {
        final origin = inferFastenApiOrigin(
          'https://embed.connect.fastenlabs.com/widget$suffix',
        );
        expect(
          origin,
          Uri.parse('https://api.connect.fastenlabs.com/'),
          reason: 'Embed URL suffix: $suffix',
        );
        expect(origin!.hasQuery, isFalse, reason: suffix);
        expect(origin.hasFragment, isFalse, reason: suffix);
      }
    });

    test('does not copy user info into the inferred API origin', () {
      expect(
        inferFastenApiOrigin(
          'https://user:password@embed.connect.fastenlabs.com/widget',
        ),
        Uri.parse('https://api.connect.fastenlabs.com/'),
      );
    });

    test('preserves a non-default port in the inferred API origin', () {
      expect(
        inferFastenApiOrigin('https://embed.example.com:8443/widget'),
        Uri.parse('https://api.example.com:8443/'),
      );
    });

    test('does not infer a non-standard or malformed embed origin', () {
      expect(inferFastenApiOrigin('https://custom.example.com/'), isNull);
      expect(inferFastenApiOrigin('not a URL'), isNull);
      expect(inferFastenApiOrigin('https://[invalid'), isNull);
    });
  });

  group('isFastenCallbackUrl', () {
    const callbackPaths = [
      '/v1/bridge/callback',
      '/v1/bridge/identity_verification/callback',
    ];
    final productionOrigin =
        inferFastenApiOrigin('https://embed.connect.fastenhealth.com/');
    final developmentOrigin =
        inferFastenApiOrigin('https://embed.connect.fastenlabs.com/');

    test('accepts supported callback paths on the inferred origin', () {
      expect(
        isFastenCallbackUrl(
          'https://api.connect.fastenhealth.com/v1/bridge/callback?state=1',
          productionOrigin,
        ),
        isTrue,
      );
      expect(
        isFastenCallbackUrl(
          'https://api.connect.fastenlabs.com/v1/bridge/identity_verification/callback?code=abc',
          developmentOrigin,
        ),
        isTrue,
      );
    });

    test('requires the configured custom port for both callback paths', () {
      final origin = inferFastenApiOrigin(
        'https://embed.connect.fastenlabs.com:8443/widget?existing=true#section',
      );
      for (final path in callbackPaths) {
        for (final port in [':8443', '', ':9443']) {
          final url =
              'https://api.connect.fastenlabs.com$port$path?code=abc#section';
          expect(
            isFastenCallbackUrl(url, origin),
            port == ':8443',
            reason: url,
          );
        }
      }
    });

    test('treats explicit and implicit default HTTPS ports as equivalent', () {
      for (final embedPort in ['', ':443']) {
        final origin = inferFastenApiOrigin(
          'https://embed.connect.fastenhealth.com$embedPort/',
        );
        for (final path in callbackPaths) {
          for (final callbackPort in ['', ':443']) {
            final url =
                'https://api.connect.fastenhealth.com$callbackPort$path';
            expect(
              isFastenCallbackUrl(url, origin),
              isTrue,
              reason: 'Embed port "$embedPort", callback: $url',
            );
          }
        }
      }
    });

    test('rejects a callback URL that cannot be parsed without throwing', () {
      expect(
          isFastenCallbackUrl('https://[invalid', productionOrigin), isFalse);
    });

    test('rejects callbacks from a different environment or origin', () {
      expect(
        isFastenCallbackUrl(
          'https://api.connect.fastenlabs.com/v1/bridge/callback',
          productionOrigin,
        ),
        isFalse,
      );
      expect(
        isFastenCallbackUrl(
          'http://api.connect.fastenhealth.com/v1/bridge/callback',
          productionOrigin,
        ),
        isFalse,
      );
    });

    test('rejects deceptive hosts, query lookalikes, and other paths', () {
      expect(
        isFastenCallbackUrl(
          'https://api.connect.fastenhealth.com.evil.example/v1/bridge/callback',
          productionOrigin,
        ),
        isFalse,
      );
      expect(
        isFastenCallbackUrl(
          'https://evil.example/?next=https://api.connect.fastenhealth.com/v1/bridge/callback',
          productionOrigin,
        ),
        isFalse,
      );
      expect(
        isFastenCallbackUrl(
          'https://api.connect.fastenhealth.com/v1/bridge/not-a-callback',
          productionOrigin,
        ),
        isFalse,
      );
      expect(isFastenCallbackUrl('not a URL', productionOrigin), isFalse);
      expect(
        isFastenCallbackUrl(
          'https://api.connect.fastenhealth.com/v1/bridge/callback',
          null,
        ),
        isFalse,
      );
    });
  });
}
