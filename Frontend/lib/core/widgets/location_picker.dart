import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

class PickedLocation {
  const PickedLocation(this.latitude, this.longitude, {this.source = 'pin'});
  final double latitude, longitude;
  final String source;
}

class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    this.latitude,
    this.longitude,
    this.source = 'pin',
    this.accuracyMetres,
  });
  final double? latitude, longitude;
  final String source;
  final double? accuracyMetres;
  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _mapController = MapController();
  bool _mapReady = false;
  LatLng? _point;
  late final TextEditingController _lat, _lon;
  String? _error;
  late String _source;
  final _tileProvider = NetworkTileProvider(
    cachingProvider: kIsWeb
        ? null
        : BuiltInMapCachingProvider.getOrCreateInstance(
            maxCacheSize: 64 * 1024 * 1024,
          ),
  );
  @override
  void initState() {
    super.initState();
    _source = widget.source;
    if (widget.latitude != null && widget.longitude != null) {
      _point = LatLng(widget.latitude!, widget.longitude!);
    }
    _lat = TextEditingController(text: widget.latitude?.toString() ?? '');
    _lon = TextEditingController(text: widget.longitude?.toString() ?? '');
  }

  @override
  void dispose() {
    _tileProvider.dispose();
    _mapController.dispose();
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  void _choose(LatLng point) {
    setState(() {
      _point = point;
      _source = 'pin';
      _lat.text = point.latitude.toStringAsFixed(6);
      _lon.text = point.longitude.toStringAsFixed(6);
      _error = null;
    });
  }

  void _confirm() {
    final lat = double.tryParse(_lat.text.trim()),
        lon = double.tryParse(_lon.text.trim());
    if (lat == null ||
        lon == null ||
        !lat.isFinite ||
        !lon.isFinite ||
        lat.abs() > 90 ||
        lon.abs() > 180) {
      setState(() => _error = 'Nhập hoặc ghim đủ hai tọa độ hợp lệ.');
      return;
    }
    Navigator.pop(context, PickedLocation(lat, lon, source: _source));
  }

  void _coordinatesChanged(String _) {
    final lat = double.tryParse(_lat.text.trim());
    final lon = double.tryParse(_lon.text.trim());
    setState(() {
      _source = 'pin';
      _error = null;
      if (lat != null &&
          lon != null &&
          lat.isFinite &&
          lon.isFinite &&
          lat.abs() <= 90 &&
          lon.abs() <= 180) {
        _point = LatLng(lat, lon);
        if (_mapReady) _mapController.move(_point!, 15);
      }
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.source == 'gps'
          ? 'Kiểm tra vị trí GPS'
          : 'Ghim vị trí cần cứu trợ',
    ),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Kiểm tra điểm ghim. Chạm lên bản đồ để đổi vị trí hoặc nhập tọa độ đã biết.',
            ),
            if (widget.accuracyMetres?.isFinite == true)
              Text(
                'Sai số GPS khoảng ${widget.accuracyMetres!.round()} m. Chỉnh lại điểm ghim nếu cần.',
              ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    onMapReady: () => _mapReady = true,
                    initialCenter: _point ?? const LatLng(16, 106),
                    initialZoom: _point == null ? 5 : 15,
                    maxZoom: 19,
                    onTap: (_, point) => _choose(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: const String.fromEnvironment(
                        'MAP_TILE_URL',
                        defaultValue:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      userAgentPackageName: 'com.dacn.flood_relief',
                      tileProvider: _tileProvider,
                      panBuffer: 0,
                      maxNativeZoom: 19,
                    ),
                    MarkerLayer(
                      markers: [
                        if (_point != null)
                          Marker(
                            point: _point!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.danger,
                              size: 38,
                            ),
                          ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ColoredBox(
                        color: Colors.white,
                        child: TextButton(
                          onPressed: () => launchUrl(
                            Uri.parse(
                              'https://www.openstreetmap.org/copyright',
                            ),
                          ),
                          child: const Text(
                            '© OpenStreetMap contributors',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lat,
              onChanged: _coordinatesChanged,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Vĩ độ (-90 đến 90)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lon,
              onChanged: _coordinatesChanged,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Kinh độ (-180 đến 180)',
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Quay lại'),
      ),
      TextButton(onPressed: _confirm, child: const Text('Xác nhận vị trí')),
    ],
  );
}
