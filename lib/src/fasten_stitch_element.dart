import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'fasten_stitch_message.dart';
import 'query_params.dart';

typedef FastenStitchEventHandler = void Function(Object? event);
typedef FastenStitchCloseButtonBuilder = Widget Function(
  BuildContext context,
  VoidCallback onClose,
);

class FastenStitchElement extends StatefulWidget {
  const FastenStitchElement({
    super.key,
    required this.publicId,
    this.debugModeEnabled = false,
    this.externalId,
    this.staticBackdrop = false,
    this.reconnectOrgConnectionId,
    this.brandId,
    this.portalId,
    this.endpointId,
    this.searchQuery,
    this.searchSortBy,
    this.searchSortByOpts,
    this.searchOnly,
    this.showSplash,
    this.tefcaMode,
    this.tefcaCspPromptForce,
    this.eventTypes,
    this.onEventBus,
    this.closeButtonBuilder,
    this.embedBaseUrl = 'https://embed.connect.fastenhealth.com/',
  });

  final String publicId;
  final bool debugModeEnabled;
  final String? externalId;
  final bool staticBackdrop;
  final String? reconnectOrgConnectionId;
  final String? brandId;
  final String? portalId;
  final String? endpointId;
  final String? searchQuery;
  final String? searchSortBy;
  final String? searchSortByOpts;
  final bool? searchOnly;
  final bool? showSplash;
  final bool? tefcaMode;
  final bool? tefcaCspPromptForce;
  final String? eventTypes;
  final FastenStitchEventHandler? onEventBus;
  final FastenStitchCloseButtonBuilder? closeButtonBuilder;
  final String embedBaseUrl;

  @override
  State<FastenStitchElement> createState() => _FastenStitchElementState();
}

class _FastenStitchElementState extends State<FastenStitchElement> {
  var _modalVisible = false;

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(_buildEmbedUrl())),
      initialSettings: _createWebViewSettings(widget.debugModeEnabled),
      initialUserScripts: _bridgeScripts,
      onWebViewCreated: _registerJavaScriptBridge,
      onCreateWindow: (controller, createWindowAction) async {
        unawaited(
          _openModal(
            windowId: createWindowAction.windowId,
            url: createWindowAction.request.url?.toString(),
          ),
        );
        return true;
      },
      onReceivedError: (controller, request, error) {
        debugPrint(
          '[FastenStitchElement PrimaryWebView] ${request.url}: '
          '${error.description}',
        );
      },
      onConsoleMessage: (controller, consoleMessage) {
        if (widget.debugModeEnabled) {
          debugPrint('[FastenStitchElement PrimaryWebView] $consoleMessage');
        }
      },
    );
  }

  String _buildEmbedUrl() {
    final queryString = encodeFastenStitchElementOptionsAsQueryString(
      FastenStitchElementQueryOptions(
        publicId: widget.publicId,
        externalId: widget.externalId,
        staticBackdrop: widget.staticBackdrop,
        reconnectOrgConnectionId: widget.reconnectOrgConnectionId,
        brandId: widget.brandId,
        portalId: widget.portalId,
        endpointId: widget.endpointId,
        searchQuery: widget.searchQuery,
        searchSortBy: widget.searchSortBy,
        searchSortByOpts: widget.searchSortByOpts,
        searchOnly: widget.searchOnly,
        showSplash: widget.showSplash,
        tefcaMode: widget.tefcaMode,
        tefcaCspPromptForce: widget.tefcaCspPromptForce,
        eventTypes: widget.eventTypes,
      ),
    );

    final separator = widget.embedBaseUrl.contains('?') ? '&' : '?';
    return '${widget.embedBaseUrl}$separator$queryString';
  }

  void _registerJavaScriptBridge(InAppWebViewController controller) {
    controller.addJavaScriptHandler(
      handlerName: _javascriptMessageHandlerName,
      callback: (arguments) {
        if (arguments.isEmpty) {
          debugPrint('[FastenStitchElement] empty message received');
          return null;
        }
        _handleBridgeMessage(
          arguments.first,
          currentWebviewEntity: communicationEntityPrimaryWebView,
        );
        return null;
      },
    );
  }

  void _handleBridgeMessage(
    Object? data, {
    required String currentWebviewEntity,
  }) {
    final FastenStitchElementMessage? message;
    try {
      message = parseFastenStitchElementMessage(data);
    } catch (error) {
      debugPrint('[$currentWebviewEntity] failed to parse message: $error');
      return;
    }

    if (message == null) {
      debugPrint('[$currentWebviewEntity] ignored non-object message');
      return;
    }

    if (message.isModalCloseRequest) {
      debugPrint('[$currentWebviewEntity] received modal close request');
      unawaited(_dismissModal());
      return;
    }

    if (message.isWindowOpenRequest) {
      unawaited(_openModal(url: message.targetUrl));
      return;
    }

    if (message.isExternalMessage) {
      final payload = message.payload;
      if (payload == null) {
        debugPrint('[FastenStitchElement] empty payload received');
        return;
      }

      try {
        widget.onEventBus?.call(parseFastenStitchPayload(payload));
        if (widget.onEventBus == null) {
          debugPrint('[FastenStitchElement] onEventBus handler missing');
        }
      } catch (error) {
        debugPrint('[FastenStitchElement] failed to parse payload: $error');
      }
    }
  }

  Future<void> _openModal({int? windowId, String? url}) async {
    if (!mounted || _modalVisible) {
      return;
    }

    _modalVisible = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !widget.staticBackdrop,
        builder: (dialogContext) {
          return Dialog.fullscreen(
            child: _FastenStitchModalWebView(
              windowId: windowId,
              initialUrl: url,
              debugModeEnabled: widget.debugModeEnabled,
              closeButtonBuilder: widget.closeButtonBuilder,
              onDismiss: () {
                Navigator.of(dialogContext).maybePop();
              },
              onBridgeMessage: (data) {
                _handleBridgeMessage(
                  data,
                  currentWebviewEntity: communicationEntityModalWebView,
                );
              },
            ),
          );
        },
      );
    } finally {
      _modalVisible = false;
    }
  }

  Future<void> _dismissModal() async {
    if (!mounted || !_modalVisible) {
      return;
    }
    await Navigator.of(context, rootNavigator: true).maybePop();
  }
}

class _FastenStitchModalWebView extends StatelessWidget {
  const _FastenStitchModalWebView({
    required this.debugModeEnabled,
    required this.onDismiss,
    required this.onBridgeMessage,
    this.windowId,
    this.initialUrl,
    this.closeButtonBuilder,
  });

  final int? windowId;
  final String? initialUrl;
  final bool debugModeEnabled;
  final VoidCallback onDismiss;
  final ValueChanged<Object?> onBridgeMessage;
  final FastenStitchCloseButtonBuilder? closeButtonBuilder;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Stack(
        children: [
          Positioned.fill(
            child: InAppWebView(
              windowId: windowId,
              initialUrlRequest: windowId == null && initialUrl != null
                  ? URLRequest(url: WebUri(initialUrl!))
                  : null,
              initialSettings: _createWebViewSettings(debugModeEnabled),
              initialUserScripts: _bridgeScripts,
              onWebViewCreated: (controller) {
                controller.addJavaScriptHandler(
                  handlerName: _javascriptMessageHandlerName,
                  callback: (arguments) {
                    if (arguments.isNotEmpty) {
                      onBridgeMessage(arguments.first);
                    }
                    return null;
                  },
                );
              },
              onLoadStop: (controller, url) {
                if (url != null && _isFastenCallbackUrl(url.toString())) {
                  onDismiss();
                }
              },
              onCloseWindow: (controller) {
                onDismiss();
              },
              onReceivedError: (controller, request, error) {
                debugPrint(
                  '[FastenStitchElement ModalWebView] ${request.url}: '
                  '${error.description}',
                );
              },
              onConsoleMessage: (controller, consoleMessage) {
                if (debugModeEnabled) {
                  debugPrint('[FastenStitchElement ModalWebView] $consoleMessage');
                }
              },
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 8,
            child: closeButtonBuilder?.call(context, onDismiss) ??
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  child: IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: onDismiss,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

bool _isFastenCallbackUrl(String url) {
  return url.contains('fastenhealth.com/v1/bridge/callback') ||
      url.contains(
        'fastenhealth.com/v1/bridge/identity_verification/callback',
      );
}

InAppWebViewSettings _createWebViewSettings(bool debugModeEnabled) {
  return InAppWebViewSettings(
    javaScriptEnabled: true,
    javaScriptCanOpenWindowsAutomatically: true,
    supportMultipleWindows: true,
    databaseEnabled: true,
    domStorageEnabled: true,
    isInspectable: debugModeEnabled,
    mediaPlaybackRequiresUserGesture: false,
    mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
  );
}

const _javascriptMessageHandlerName = 'FastenStitchMessage';

final _bridgeScripts = UnmodifiableListView<UserScript>([
  UserScript(
    groupName: 'fasten-stitch-flutter-bridge',
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    source: '''
(function () {
  if (window.__fastenStitchFlutterBridgeInstalled) {
    return;
  }

  window.__fastenStitchFlutterBridgeInstalled = true;

  var pendingMessages = [];

  function normalizeMessage(message) {
    return typeof message === 'string' ? message : JSON.stringify(message);
  }

  function sendToFlutter(message) {
    var normalizedMessage = normalizeMessage(message);
    if (
      window.flutter_inappwebview &&
      typeof window.flutter_inappwebview.callHandler === 'function'
    ) {
      window.flutter_inappwebview.callHandler(
        'FastenStitchMessage',
        normalizedMessage
      );
      return;
    }
    pendingMessages.push(normalizedMessage);
  }

  window.addEventListener('flutterInAppWebViewPlatformReady', function () {
    if (
      !window.flutter_inappwebview ||
      typeof window.flutter_inappwebview.callHandler !== 'function'
    ) {
      return;
    }

    var messagesToFlush = pendingMessages.slice();
    pendingMessages = [];
    for (var i = 0; i < messagesToFlush.length; i += 1) {
      window.flutter_inappwebview.callHandler(
        'FastenStitchMessage',
        messagesToFlush[i]
      );
    }
  });

  window.ReactNativeWebView = window.ReactNativeWebView || {};
  window.ReactNativeWebView.postMessage = sendToFlutter;
  window.FastenStitchFlutter = {
    postMessage: sendToFlutter
  };

  var originalOpen = window.open;
  window.open = function (url, target, features) {
    if (url) {
      sendToFlutter({
        action: 'FASTEN_CONNECT_WINDOW_OPEN_REQUEST',
        to: 'FASTEN_CONNECT_FLUTTER_WEBVIEW',
        targetUrl: String(url)
      });
      return null;
    }

    if (originalOpen) {
      return originalOpen.apply(window, arguments);
    }

    return null;
  };
})();
''',
  ),
]);
