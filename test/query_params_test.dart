import 'dart:convert';

import 'package:fasten_stitch_element_flutter/fasten_stitch_element.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodes required Fasten Connect parameters', () {
    final query = encodeFastenStitchElementOptionsAsQueryString(
      const FastenStitchElementQueryOptions(publicId: 'public_test_123'),
    );
    final params = Uri.splitQueryString(query);

    expect(params['public-id'], 'public_test_123');
    expect(params['connect-mode'], 'websocket');
    expect(params['sdk-mode'], 'flutter');
  });

  test('encodes search-only options like the React Native SDK', () {
    final query = encodeFastenStitchElementOptionsAsQueryString(
      const FastenStitchElementQueryOptions(
        publicId: 'public_test_123',
        searchOnly: true,
        searchQuery: 'hospital',
        searchSortBy: 'distance',
        searchSortByOpts: '{"lat":1,"lng":2}',
        showSplash: true,
      ),
    );
    final params = Uri.splitQueryString(query);

    expect(params['search-only'], 'true');
    expect(params['search-query'], 'hospital');
    expect(params['search-sort-by'], 'distance');
    expect(
      utf8.decode(base64.decode(params['search-sort-by-opts']!)),
      '{"lat":1,"lng":2}',
    );
    expect(params['show-splash'], 'true');
  });

  test('tefca mode forces search-only false', () {
    final query = encodeFastenStitchElementOptionsAsQueryString(
      const FastenStitchElementQueryOptions(
        publicId: 'public_test_123',
        searchOnly: true,
        tefcaMode: true,
        tefcaCspPromptForce: true,
      ),
    );
    final params = Uri.splitQueryString(query);

    expect(params['tefca-mode'], 'true');
    expect(params['search-only'], 'false');
    expect(params['tefca-csp-prompt-force'], 'true');
  });

  test('parses external event bus messages', () {
    final message = parseFastenStitchElementMessage(
      jsonEncode({
        'to': communicationEntityExternal,
        'payload': jsonEncode({'event_type': 'connection.created'}),
      }),
    );

    expect(message, isNotNull);
    expect(message!.isExternalMessage, isTrue);
    expect(
      parseFastenStitchPayload(message.payload),
      {'event_type': 'connection.created'},
    );
  });

  test('recognizes modal close requests for Flutter and React Native targets', () {
    final flutterMessage = FastenStitchElementMessage.fromJson({
      'action': communicationActionModalWebviewCloseRequest,
      'to': communicationEntityFlutterComponent,
    });
    final reactNativeMessage = FastenStitchElementMessage.fromJson({
      'action': communicationActionModalWebviewCloseRequest,
      'to': communicationEntityReactNativeComponent,
    });

    expect(flutterMessage.isModalCloseRequest, isTrue);
    expect(reactNativeMessage.isModalCloseRequest, isTrue);
  });
}

