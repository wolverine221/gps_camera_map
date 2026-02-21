# Changelog

## 0.0.4
- **Tile Caching**: Map tiles are now cached to disk (enabled by default via `cacheTiles: true`). Significantly reduces API hits when working in the same area repeatedly.
- **API Failure Fallback**: If map tiles fail to load (API down, rate limited, or invalid key), the overlay gracefully falls back to showing latitude/longitude text instead of a broken map.
- **Google Maps Support**: Added `MapProvider` enum and `googleMapsApiKey` config. Set `mapProvider: MapProvider.googleMaps` to use Google Maps tiles instead of MapTiler.
- Example app no longer exits on invalid API key — map gracefully degrades.

## 0.0.3
- Improved documentation and usage instructions.
- Minor internal improvements.

## 0.0.2
- Added support for passing the MapTiler API key using `--dart-define`.
- Improved documentation and usage instructions.
- Minor internal improvements.

## 0.0.1
- Initial release.
