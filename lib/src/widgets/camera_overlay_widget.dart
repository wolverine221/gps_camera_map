import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../models/gps_camera_config.dart';

class CameraOverlayWidget extends StatelessWidget {
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
              if (config.showMap) _buildMap(context),
              const SizedBox(width: 12),
              Expanded(child: _buildDetails()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
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
            initialCenter: position,
            initialZoom: 15.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName:
                  'com.example.gps_camera_snap', // Required by OSM
              tileProvider: NetworkTileProvider(),
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: position,
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

  Widget _buildDetails() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('hh:mm:ss a');

    String address = "Loading Address...";
    if (placemark != null) {
      address = [
        placemark!.street,
        placemark!.subLocality,
        placemark!.locality,
        placemark!.administrativeArea,
        placemark!.country,
      ].where((e) => e != null && e.isNotEmpty).join(", ");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (config.showAddress)
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
        if (config.showCoordinates)
          Text(
            "Lat: ${position.latitude.toStringAsFixed(4)}  Long: ${position.longitude.toStringAsFixed(4)}",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
          ),
        const SizedBox(height: 4),
        if (config.showDate || config.showTime)
          Text(
            "${dateFormat.format(dateTime)}, ${timeFormat.format(dateTime)}",
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
