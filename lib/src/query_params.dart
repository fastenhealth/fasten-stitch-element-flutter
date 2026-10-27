import 'dart:convert';

class FastenStitchElementQueryOptions {
  const FastenStitchElementQueryOptions({
    required this.publicId,
    this.externalId,
    this.staticBackdrop,
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
    this.sdkMode = 'flutter',
  });

  final String publicId;
  final String? externalId;
  final bool? staticBackdrop;
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
  final String sdkMode;
}

String encodeFastenStitchElementOptionsAsQueryString(
  FastenStitchElementQueryOptions options,
) {
  final params = <String, String>{
    'public-id': options.publicId,
  };

  void addString(String key, String? value) {
    if (value != null && value.isNotEmpty) {
      params[key] = value;
    }
  }

  void addBool(String key, bool? value) {
    if (value != null) {
      params[key] = value.toString();
    }
  }

  addString('external-id', options.externalId);
  addString(
    'reconnect-org-connection-id',
    options.reconnectOrgConnectionId,
  );

  if (options.searchOnly == true) {
    addBool('search-only', options.searchOnly);
    addString('search-query', options.searchQuery);
    addString('search-sort-by', options.searchSortBy);

    if (options.searchSortBy != null && options.searchSortByOpts != null) {
      params['search-sort-by-opts'] = base64.encode(
        utf8.encode(options.searchSortByOpts!),
      );
    }

    addBool('show-splash', options.showSplash);
  }

  addString('brand-id', options.brandId);
  addString('portal-id', options.portalId);
  addString('endpoint-id', options.endpointId);

  if (options.tefcaMode == true) {
    addBool('tefca-mode', options.tefcaMode);
    params['search-only'] = 'false';
    addBool('tefca-csp-prompt-force', options.tefcaCspPromptForce);
  }

  addString('event-types', options.eventTypes);

  params['connect-mode'] = 'websocket';
  params['sdk-mode'] = options.sdkMode;

  return Uri(queryParameters: params).query;
}

