import 'dart:convert';

const communicationEntityPrimaryWebView = 'FASTEN_CONNECT_PRIMARY_WEBVIEW';
const communicationEntityModalWebView = 'FASTEN_CONNECT_MODAL_WEBVIEW';
const communicationEntityFlutterComponent = 'FASTEN_CONNECT_FLUTTER_WEBVIEW';
const communicationEntityReactNativeComponent = 'FASTEN_CONNECT_REACT_WEBVIEW';
const communicationEntityExternal = 'FASTEN_CONNECT_EXTERNAL';

const communicationActionModalWebviewCloseRequest =
    'FASTEN_CONNECT_MODAL_WEBVIEW_CLOSE_REQUEST';
const communicationActionWindowOpenRequest =
    'FASTEN_CONNECT_WINDOW_OPEN_REQUEST';

class FastenStitchElementMessage {
  const FastenStitchElementMessage({
    this.action,
    this.to,
    this.payload,
    this.targetUrl,
  });

  factory FastenStitchElementMessage.fromJson(Map<String, dynamic> json) {
    return FastenStitchElementMessage(
      action: json['action'] as String?,
      to: json['to'] as String?,
      payload: json['payload'],
      targetUrl: json['targetUrl'] as String?,
    );
  }

  final String? action;
  final String? to;
  final Object? payload;
  final String? targetUrl;

  bool get isModalCloseRequest {
    return action == communicationActionModalWebviewCloseRequest &&
        (to == communicationEntityFlutterComponent ||
            to == communicationEntityReactNativeComponent);
  }

  bool get isExternalMessage => to == communicationEntityExternal;

  bool get isWindowOpenRequest {
    return action == communicationActionWindowOpenRequest &&
        targetUrl != null &&
        targetUrl!.isNotEmpty;
  }
}

FastenStitchElementMessage? parseFastenStitchElementMessage(Object? data) {
  if (data == null) {
    return null;
  }

  final Object? decoded = data is String ? jsonDecode(data) : data;
  if (decoded is! Map) {
    return null;
  }

  return FastenStitchElementMessage.fromJson(
    decoded.cast<String, dynamic>(),
  );
}

Object? parseFastenStitchPayload(Object? payload) {
  if (payload == null) {
    return null;
  }
  if (payload is String) {
    return jsonDecode(payload);
  }
  return payload;
}

