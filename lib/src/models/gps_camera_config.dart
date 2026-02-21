import '../tiles/region_cache_manager.dart';

enum CameraAspectMode { square, portrait, fullscreen }

/// Map tile provider to use for the overlay map.
enum MapProvider {
  /// Use MapTiler tiles (default). Requires [GpsCameraConfig.mapTilerApiKey].
  mapTiler,

  /// Use Google Maps tiles. Requires [GpsCameraConfig.googleMapsApiKey].
  googleMaps,
}

/// Configuration for [GpsCamera].
///
/// ## Tile provider priority (highest → lowest)
///
/// 1. **[regionCacheManager]** — pre-warmed disk cache.
///    Zero API hits after prewarm. Works offline. Auto-saves any
///    tiles fetched outside the pre-warmed area.
///
/// 2. **[cacheTiles]** (default `true`) — flutter_map's built-in disk cache.
///    Used when [regionCacheManager] is null. Tiles fetched live on first
///    use, then served from disk.
///
/// 3. **Live network only** — used when [cacheTiles] is false.
class GpsCameraConfig {
  /// MapTiler API key. Get a free key at https://www.maptiler.com/
  final String mapTilerApiKey;

  /// Which map tile provider to use. Defaults to [MapProvider.mapTiler].
  final MapProvider mapProvider;

  /// Google Maps API key. Required when [mapProvider] is [MapProvider.googleMaps].
  final String? googleMapsApiKey;

  final bool showMap;
  final bool showAddress;
  final bool showDate;
  final bool showTime;
  final bool showCoordinates;
  final CameraAspectMode aspectMode;

  /// Whether to cache map tiles to disk using flutter_map's built-in cache.
  /// Only used when [regionCacheManager] is null. Defaults to `true`.
  final bool cacheTiles;

  /// Optional [RegionCacheManager] for pre-warmed regional tile caching.
  ///
  /// When provided, the overlay map will:
  /// - Serve pre-warmed tiles from disk instantly (zero API hits, offline-capable)
  /// - Auto-fetch + save any tile not yet in cache (e.g. first visit to new area)
  /// - Fall back to lat/lng display if network is unavailable
  ///
  /// ## Setup
  /// ```dart
  /// final cacheManager = RegionCacheManager(
  ///   tileUrlTemplate:
  ///     'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=KEY',
  /// );
  ///
  /// // Pre-warm once on first app launch (background, non-blocking)
  /// cacheManager.prewarm(CacheRegion.keralaAndBorders).listen((p) {
  ///   print('${p.percentString} — zoom ${p.currentZoom}');
  /// });
  ///
  /// GpsCameraConfig(
  ///   mapTilerApiKey: 'KEY',
  ///   regionCacheManager: cacheManager,
  ///   cacheRegion: CacheRegion.keralaAndBorders,
  /// )
  /// ```
  final RegionCacheManager? regionCacheManager;

  /// The region used with [regionCacheManager].
  /// Defaults to [CacheRegion.keralaAndBorders] when manager is provided.
  final CacheRegion? cacheRegion;

  const GpsCameraConfig({
    required this.mapTilerApiKey,
    this.mapProvider = MapProvider.mapTiler,
    this.googleMapsApiKey,
    this.showMap = true,
    this.showAddress = true,
    this.showDate = true,
    this.showTime = true,
    this.showCoordinates = true,
    this.aspectMode = CameraAspectMode.portrait,
    this.cacheTiles = true,
    this.regionCacheManager,
    this.cacheRegion,
  });

  double get aspectRatio {
    switch (aspectMode) {
      case CameraAspectMode.square:
        return 1.0;
      case CameraAspectMode.portrait:
        return 3 / 4;
      case CameraAspectMode.fullscreen:
        return 9 / 16;
    }
  }

  String get activeApiKey {
    switch (mapProvider) {
      case MapProvider.mapTiler:
        return mapTilerApiKey;
      case MapProvider.googleMaps:
        return googleMapsApiKey ?? '';
    }
  }
}
