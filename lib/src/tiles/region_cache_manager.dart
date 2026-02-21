import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// ── Tile math helpers (module-level, used by CacheRegion too) ─────────────

int _lngToX(double lng, int z) => ((lng + 180) / 360 * (1 << z)).floor();

int _latToY(double lat, int z) {
  final r = lat * pi / 180;
  return ((1 - log(tan(r) + 1 / cos(r)) / pi) / 2 * (1 << z)).floor();
}

// ── CacheRegion ───────────────────────────────────────────────────────────

/// Defines a geographic bounding box and zoom range for tile pre-caching.
class CacheRegion {
  final String name;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
  final int minZoom;
  final int maxZoom;

  const CacheRegion({
    required this.name,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.minZoom,
    required this.maxZoom,
  });

  /// Kerala + ~80 km buffer into Tamil Nadu & Karnataka borders.
  ///
  /// Coverage:
  /// - Full Kerala coastline (Arabian Sea)
  /// - South : Kanyakumari, Nagercoil (TN)
  /// - East  : Coimbatore, Ooty, Mysore border areas
  /// - North : Mangalore, Kodagu (KA)
  ///
  /// Zoom z13–z15 gives street-level detail for the camera overlay.
  static const keralaAndBorders = CacheRegion(
    name: 'kerala_borders',
    minLat: 7.8,  // Kanyakumari tip
    maxLat: 13.5, // Mangalore / Kodagu
    minLng: 74.5, // Arabian Sea coast
    maxLng: 78.5, // Coimbatore / Mysore side
    minZoom: 13,
    maxZoom: 15,
  );

  /// Total number of tiles in this region across all zoom levels.
  int get totalTiles {
    int count = 0;
    for (int z = minZoom; z <= maxZoom; z++) {
      final x0 = _lngToX(minLng, z);
      final x1 = _lngToX(maxLng, z);
      final y0 = _latToY(maxLat, z);
      final y1 = _latToY(minLat, z);
      count += (x1 - x0 + 1) * (y1 - y0 + 1);
    }
    return count;
  }
}

// ── CacheProgress ─────────────────────────────────────────────────────────

/// Progress snapshot emitted by [RegionCacheManager.prewarm].
class CacheProgress {
  final int total;
  final int completed;
  final int downloaded;
  final int skipped;
  final int failed;
  final int currentZoom;
  final bool isDone;

  const CacheProgress({
    required this.total,
    required this.completed,
    required this.downloaded,
    required this.skipped,
    required this.failed,
    required this.currentZoom,
    required this.isDone,
  });

  /// 0.0 → 1.0
  double get percent => total == 0 ? 0 : completed / total;

  /// e.g. "42.3%"
  String get percentString => '${(percent * 100).toStringAsFixed(1)}%';
}

// ── RegionCacheManager ────────────────────────────────────────────────────

/// Downloads and serves map tiles for a [CacheRegion] from the device's
/// local cache directory.
///
/// ## Quick start
///
/// ```dart
/// // Create once (top-level or in a provider)
/// final cacheManager = RegionCacheManager(
///   tileUrlTemplate:
///     'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=KEY',
/// );
///
/// // Pre-warm once on first launch (shows progress)
/// cacheManager.prewarm(CacheRegion.keralaAndBorders).listen((p) {
///   print('${p.percentString}  zoom ${p.currentZoom}');
///   if (p.isDone) print('Ready!');
/// });
///
/// // Pass into GpsCameraConfig
/// GpsCameraConfig(
///   mapTilerApiKey: 'KEY',
///   regionCacheManager: cacheManager,
///   cacheRegion: CacheRegion.keralaAndBorders,
/// )
/// ```
///
/// Tiles are stored at:
/// `<appCacheDir>/gps_snap_tiles/<regionName>/<z>/<x>/<y>.png`
class RegionCacheManager {
  final String tileUrlTemplate;

  /// Polite delay between requests (default 25 ms).
  final Duration requestDelay;

  /// Per-tile HTTP timeout (default 10 s).
  final Duration timeout;

  String? _baseCacheDir;

  RegionCacheManager({
    required this.tileUrlTemplate,
    this.requestDelay = const Duration(milliseconds: 25),
    this.timeout = const Duration(seconds: 10),
  });

  // ── Internal path helpers ─────────────────────────────────────────────

  Future<String> _baseDir() async {
    _baseCacheDir ??= (await getApplicationCacheDirectory()).path;
    return _baseCacheDir!;
  }

  /// Returns the [File] for a tile (may not exist yet).
  Future<File> tileFile(int z, int x, int y, String regionName) async {
    final base = await _baseDir();
    return File(p.join(base, 'gps_snap_tiles', regionName, '$z', '$x', '$y.png'));
  }

  /// Returns the [File] if already cached, or null.
  Future<File?> cachedTile(int z, int x, int y, String regionName) async {
    final f = await tileFile(z, x, y, regionName);
    return f.existsSync() ? f : null;
  }

  String _url(int z, int x, int y) => tileUrlTemplate
      .replaceAll('{z}', '$z')
      .replaceAll('{x}', '$x')
      .replaceAll('{y}', '$y');

  // ── Pre-warm ──────────────────────────────────────────────────────────

  /// Pre-warms the disk cache for [region].
  ///
  /// - Emits [CacheProgress] roughly every 10 tiles.
  /// - **Resume-safe** — already-cached tiles are skipped instantly.
  /// - Safe to call multiple times; never re-downloads existing tiles.
  /// - Call [isRegionCached] first to skip entirely if already done.
  Stream<CacheProgress> prewarm(CacheRegion region) async* {
    final client = http.Client();
    final total = region.totalTiles;
    int completed = 0, downloaded = 0, skipped = 0, failed = 0;

    debugPrint('[RegionCacheManager] Starting prewarm "${region.name}" '
        '— $total tiles z${region.minZoom}→z${region.maxZoom}');

    try {
      for (int z = region.minZoom; z <= region.maxZoom; z++) {
        final x0 = _lngToX(region.minLng, z);
        final x1 = _lngToX(region.maxLng, z);
        final y0 = _latToY(region.maxLat, z);
        final y1 = _latToY(region.minLat, z);

        for (int x = x0; x <= x1; x++) {
          for (int y = y0; y <= y1; y++) {
            final file = await tileFile(z, x, y, region.name);

            if (file.existsSync()) {
              skipped++;
            } else {
              try {
                final resp = await client
                    .get(Uri.parse(_url(z, x, y)))
                    .timeout(timeout);
                if (resp.statusCode == 200) {
                  await file.parent.create(recursive: true);
                  await file.writeAsBytes(resp.bodyBytes);
                  downloaded++;
                } else {
                  debugPrint(
                      '[RegionCacheManager] HTTP ${resp.statusCode} z$z/$x/$y');
                  failed++;
                }
              } catch (e) {
                debugPrint('[RegionCacheManager] Error z$z/$x/$y: $e');
                failed++;
              }
              await Future.delayed(requestDelay);
            }

            completed++;
            if (completed % 10 == 0) {
              yield CacheProgress(
                total: total,
                completed: completed,
                downloaded: downloaded,
                skipped: skipped,
                failed: failed,
                currentZoom: z,
                isDone: false,
              );
            }
          }
        }
      }
    } finally {
      client.close();
    }

    yield CacheProgress(
      total: total,
      completed: total,
      downloaded: downloaded,
      skipped: skipped,
      failed: failed,
      currentZoom: region.maxZoom,
      isDone: true,
    );

    debugPrint('[RegionCacheManager] Done — $downloaded downloaded, '
        '$skipped skipped, $failed failed');
  }

  // ── Status helpers ────────────────────────────────────────────────────

  /// Returns true if every tile in [region] is already on disk.
  Future<bool> isRegionCached(CacheRegion region) async {
    for (int z = region.minZoom; z <= region.maxZoom; z++) {
      final x0 = _lngToX(region.minLng, z);
      final x1 = _lngToX(region.maxLng, z);
      final y0 = _latToY(region.maxLat, z);
      final y1 = _latToY(region.minLat, z);
      for (int x = x0; x <= x1; x++) {
        for (int y = y0; y <= y1; y++) {
          final f = await tileFile(z, x, y, region.name);
          if (!f.existsSync()) return false;
        }
      }
    }
    return true;
  }

  /// How many tiles in [region] are already cached on disk.
  Future<int> cachedTileCount(CacheRegion region) async {
    int count = 0;
    for (int z = region.minZoom; z <= region.maxZoom; z++) {
      final x0 = _lngToX(region.minLng, z);
      final x1 = _lngToX(region.maxLng, z);
      final y0 = _latToY(region.maxLat, z);
      final y1 = _latToY(region.minLat, z);
      for (int x = x0; x <= x1; x++) {
        for (int y = y0; y <= y1; y++) {
          final f = await tileFile(z, x, y, region.name);
          if (f.existsSync()) count++;
        }
      }
    }
    return count;
  }

  /// Deletes all cached tiles for [region].
  Future<void> clearCache(CacheRegion region) async {
    final base = await _baseDir();
    final dir = Directory(
        p.join(base, 'gps_snap_tiles', region.name));
    if (dir.existsSync()) await dir.delete(recursive: true);
    debugPrint('[RegionCacheManager] Cache cleared for "${region.name}"');
  }
}
