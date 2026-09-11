const _fastenCallbackPaths = {
  '/v1/bridge/callback',
  '/v1/bridge/identity_verification/callback',
};

/// Infers the API origin associated with a standard Fasten embed origin.
///
/// For example, `https://embed.connect.fastenhealth.com/` maps to
/// `https://api.connect.fastenhealth.com/`.
Uri? inferFastenApiOrigin(String embedBaseUrl) {
  final embedUri = Uri.tryParse(embedBaseUrl);
  if (embedUri == null ||
      !embedUri.hasScheme ||
      embedUri.host.isEmpty ||
      embedUri.host.split('.').first.toLowerCase() != 'embed') {
    return null;
  }

  final hostParts = embedUri.host.split('.');
  hostParts[0] = 'api';
  return embedUri.replace(
    host: hostParts.join('.'),
    path: '/',
    query: null,
    fragment: null,
  );
}

/// Whether [url] is a Fasten callback for the configured API origin.
bool isFastenCallbackUrl(String url, Uri? expectedApiOrigin) {
  if (expectedApiOrigin == null) {
    return false;
  }

  final callbackUri = Uri.tryParse(url);
  if (callbackUri == null ||
      callbackUri.scheme.toLowerCase() !=
          expectedApiOrigin.scheme.toLowerCase() ||
      callbackUri.host.toLowerCase() != expectedApiOrigin.host.toLowerCase() ||
      callbackUri.port != expectedApiOrigin.port) {
    return false;
  }

  return _fastenCallbackPaths.contains(callbackUri.path);
}
