import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../models/gps_camera_config.dart';
import '../utils/map_tile_provider.dart';

class CameraOverlayWidget extends StatefulWidget {
  final LatLng position;
  final Placemark? placemark;
  final DateTime dateTime;
  final GpsCameraConfig config;

  const CameraOverlayWidget({
    super.key,
    required this.position,
    this.placemark,
    required this.dateTime,
    required this.config,
  });

  @override
  State<CameraOverlayWidget> createState() => _CameraOverlayWidgetState();
}

class _CameraOverlayWidgetState extends State<CameraOverlayWidget> {
  bool _mapLoadFailed = false;
  int _tileErrorCount = 0;

  /// After a few tile errors, we consider the map as failed and show fallback.
  static const int _maxTileErrors = 3;

  void _onTileError(TileImage tile, Object error, StackTrace? stackTrace) {
    _tileErrorCount++;
    if (_tileErrorCount >= _maxTileErrors && !_mapLoadFailed) {
      if (mounted) {
        setState(() {
          _mapLoadFailed = true;
        });
      }
    }
  }

  /// Strips API key query parameters from tile URLs so cached tiles
  /// are identified by coordinates only, not by API key.
  static String _stripApiKeyFromUrl(String url) {
    final uri = Uri.parse(url);
    final cleanedParams = Map<String, String>.from(uri.queryParameters)
      ..remove('key');
    final cleanedUri = uri.replace(
      queryParameters: cleanedParams.isEmpty ? null : cleanedParams,
    );
    return BuiltInMapCachingProvider.uuidTileKeyGenerator(
      cleanedUri.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(
              alpha: 0.4,
            ), // Darker at bottom for readability
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Container()), // Spacer to push content down
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.config.showMap && !_mapLoadFailed)
                _buildMap(context)
              else if (widget.config.showMap && _mapLoadFailed)
                _buildFallbackLocation(),
              const SizedBox(width: 12),
              Expanded(child: _buildDetails()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    final tileUrl = MapTileUrlBuilder.getTileUrl(widget.config);
    final userAgent = MapTileUrlBuilder.getUserAgent(widget.config);

    // Configure caching: use built-in disk cache to reduce API hits,
    // especially when working repeatedly in the same area.
    final cachingProvider = widget.config.cacheTiles
        ? BuiltInMapCachingProvider.getOrCreateInstance(
            // Strip API keys from cache keys so tiles are identified
            // by coordinates only (avoids cache misses on key changes).
            tileKeyGenerator: _stripApiKeyFromUrl,
          )
        : const DisabledMapCachingProvider();

    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: widget.position,
            initialZoom: 15.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              userAgentPackageName: userAgent,
              tileProvider: NetworkTileProvider(
                cachingProvider: cachingProvider,
              ),
              errorTileCallback: _onTileError,
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: widget.position,
                  width: 30,
                  height: 30,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Fallback widget shown when the map fails to load.
  /// Shows only lat/lng coordinates in a styled box, no location name.
  Widget _buildFallbackLocation() {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: Colors.black54,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 24),
              const SizedBox(height: 4),
              Text(
                widget.position.latitude.toStringAsFixed(4),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.position.longitude.toStringAsFixed(4),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetails() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('hh:mm:ss a');

    String address = "Loading Address...";
    if (widget.placemark != null) {
      address = [
        widget.placemark!.street,
        widget.placemark!.subLocality,
        widget.placemark!.locality,
        widget.placemark!.administrativeArea,
        widget.placemark!.country,
      ].where((e) => e != null && e.isNotEmpty).join(", ");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.config.showAddress)
          Text(
            address,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 4),
        if (widget.config.showCoordinates)
          Text(
            "Lat: ${widget.position.latitude.toStringAsFixed(4)}  Long: ${widget.position.longitude.toStringAsFixed(4)}",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
          ),
        const SizedBox(height: 4),
        if (widget.config.showDate || widget.config.showTime)
          Text(
            "${dateFormat.format(widget.dateTime)}, ${timeFormat.format(widget.dateTime)}",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
          ),
      ],
    );
  }
}
