import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

import 'region_cache_manager.dart';

/// A [TileProvider] that serves tiles from [RegionCacheManager]'s disk cache
/// when available, and falls back to the network otherwise.
///
/// Network tiles that aren't cached are saved to disk automatically after
/// the first fetch — so every tile is only ever downloaded once.
///
/// Works for any [CacheRegion]: Kerala, custom bounding boxes, etc.
/// Tiles outside the pre-warmed area still work — they're just fetched live
/// and cached on first use.
class RegionAwareTileProvider extends TileProvider {
  final RegionCacheManager manager;
  final CacheRegion region;
  final String networkFallbackUrl;
  final http.Client _httpClient;

  RegionAwareTileProvider({
    required this.manager,
    required this.region,
    required this.networkFallbackUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final networkUrl = networkFallbackUrl
        .replaceAll('{z}', '${coordinates.z}')
        .replaceAll('{x}', '${coordinates.x}')
        .replaceAll('{y}', '${coordinates.y}');

    return _CachedTileImage(
      manager: manager,
      regionName: region.name,
      z: coordinates.z,
      x: coordinates.x,
      y: coordinates.y,
      networkUrl: networkUrl,
      httpClient: _httpClient,
    );
  }
}

// ── _CachedTileImage ──────────────────────────────────────────────────────

/// Tries disk cache first; falls back to network and saves result to disk.
class _CachedTileImage extends ImageProvider<_CachedTileImage> {
  final RegionCacheManager manager;
  final String regionName;
  final int z, x, y;
  final String networkUrl;
  final http.Client httpClient;

  const _CachedTileImage({
    required this.manager,
    required this.regionName,
    required this.z,
    required this.x,
    required this.y,
    required this.networkUrl,
    required this.httpClient,
  });

  @override
  Future<_CachedTileImage> obtainKey(ImageConfiguration configuration) async =>
      this;

  @override
  ImageStreamCompleter loadImage(
    _CachedTileImage key,
    ImageDecoderCallback decode,
  ) =>
      MultiFrameImageStreamCompleter(
        codec: _load(key, decode),
        scale: 1.0,
        debugLabel: '${key.regionName}/${key.z}/${key.x}/${key.y}',
      );

  Future<ui.Codec> _load(
    _CachedTileImage key,
    ImageDecoderCallback decode,
  ) async {
    // 1. Try disk cache
    final cached =
        await key.manager.cachedTile(key.z, key.x, key.y, key.regionName);
    if (cached != null) {
      try {
        final bytes = await cached.readAsBytes();
        final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        return decode(buffer);
      } catch (_) {
        // Corrupted file — delete and re-fetch from network
        try {
          await cached.delete();
        } catch (_) {}
      }
    }

    // 2. Network fetch
    final response = await key.httpClient
        .get(Uri.parse(key.networkUrl))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw NetworkImageLoadException(
        statusCode: response.statusCode,
        uri: Uri.parse(key.networkUrl),
      );
    }

    // 3. Save to disk in background (don't block rendering)
    _saveToDisk(key, response.bodyBytes);

    final buffer = await ui.ImmutableBuffer.fromUint8List(response.bodyBytes);
    return decode(buffer);
  }

  static void _saveToDisk(_CachedTileImage key, List<int> bytes) {
    key.manager
        .tileFile(key.z, key.x, key.y, key.regionName)
        .then((file) async {
      try {
        if (!file.existsSync()) {
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes);
        }
      } catch (e) {
        debugPrint('[RegionAwareTileProvider] Save failed: $e');
      }
    });
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CachedTileImage &&
          other.regionName == regionName &&
          other.z == z &&
          other.x == x &&
          other.y == y;

  @override
  int get hashCode => Object.hash(regionName, z, x, y);
}
