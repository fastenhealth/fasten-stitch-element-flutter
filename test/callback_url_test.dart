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
          'https://embed.connect.fastenlabs.com/widget?existing=true',
        ),
        Uri.parse('https://api.connect.fastenlabs.com/'),
      );
    });

    test('does not infer a non-standard or malformed embed origin', () {
      expect(inferFastenApiOrigin('https://custom.example.com/'), isNull);
      expect(inferFastenApiOrigin('not a URL'), isNull);
    });
  });

  group('isFastenCallbackUrl', () {
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
