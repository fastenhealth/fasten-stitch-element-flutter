<p align="center">
  <a href="https://github.com/fastenhealth/">
  <img width="400" alt="fasten_view" src="https://github.com/fastenhealth/brand-kit/raw/main/connect/banner-transparent.png">
  </a>
</p>

# Fasten Connect Flutter SDK (Beta)

A lightweight Flutter SDK that embeds the Fasten Connect experience inside a native Flutter application. The package wraps the Stitch.js workflow in coordinated native WebViews so users can authenticate with provider portals and your app can receive Fasten Connect events without leaving the Flutter flow.

> **Status:** Beta - APIs may change and you should validate the integration in your environment before shipping to production.

## Installation

Add the package to your Flutter app:

```bash
flutter pub add fasten_stitch_element_flutter
```

This SDK uses `flutter_inappwebview` for native WebView and popup handling. Follow that package's platform setup notes if your app has not used it before, especially for iOS, Android, macOS, Windows, or web-specific configuration.

## Usage

```dart
import 'package:fasten_stitch_element_flutter/fasten_stitch_element.dart';
import 'package:flutter/material.dart';

const customerPublicId = 'public_test_...';

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FastenStitchElement(
          publicId: customerPublicId,
          debugModeEnabled: true,
          onEventBus: (event) {
            debugPrint('Fasten event: $event');
          },
        ),
      ),
    );
  }
}
```

`FastenStitchElement` renders to fill its parent constraints, so place it in a container that matches how you want the Connect UI to appear.

## Options

The widget accepts the same Stitch.js-oriented configuration as the React Native SDK:

- `publicId` (**required**) - Your Fasten Connect public identifier.
- `externalId` - Identifier you want to associate with the patient/session.
- `reconnectOrgConnectionId` - Reconnect a previously established patient connection.
- `searchOnly`, `searchQuery`, `searchSortBy`, `searchSortByOpts`, `showSplash` - Configure the provider search experience.
- `tefcaMode`, `tefcaCspPromptForce` - Enable and configure TEFCA flows.
- `eventTypes` - Comma-delimited list of event types to receive.
- `debugModeEnabled` - Enables WebView inspection and logs WebView console messages through Flutter debug output.
- `onEventBus` - Callback invoked with parsed payloads sent from Fasten Connect.
- `staticBackdrop` - When true, disables outside-tap dismissal of the modal WebView.

## How It Works

The Stitch.js browser workflow opens a popup for patient portal login and consent. Mobile WebViews do not handle browser popups the same way as a full browser, so this SDK uses:

- A primary WebView for the embedded Fasten Connect UI.
- A modal WebView for popup windows created by the Connect flow.
- A JavaScript bridge that maps `window.ReactNativeWebView.postMessage`, popup requests, and Fasten event bus payloads into Flutter callbacks.

The SDK automatically closes the modal when Fasten Connect sends a modal close request or when the modal reaches the Fasten callback URL.

## Development

Run the package checks locally with a Flutter SDK installed:

```bash
flutter pub get
flutter analyze
flutter test
```

## Feedback

Please open an issue with any bugs or requests. Your feedback will help stabilize the public SDK interface.

