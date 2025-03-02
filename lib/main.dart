import 'package:flutter/material.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:vietmap_flutter_navigation/vietmap_flutter_navigation.dart';
import 'package:vietmap_flutter_plugin/vietmap_flutter_plugin.dart';

void main() {
  Vietmap.getInstance('96dba6f75fbade7718abd8c97f431452bdbd4d3084614145');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxi Go',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapOptions _navigationOption;
  final _vietmapNavigationPlugin = VietMapNavigationPlugin();
  VietmapController? _mapController;

  // Điểm đón & điểm trả
  LatLng? pickupLocation;
  LatLng? dropoffLocation;

  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  List<VietmapAutocompleteModel> _pickupResults = [];
  List<VietmapAutocompleteModel> _dropoffResults = [];

  double distance = 0.0;
  double price = 0.0;
  String vehicleType = 'Xe 4 Chỗ'; // Default to Xe 4 Chỗ
  int passengerCount = 4; // Default to 4 passengers
  String note = '';

  @override
  void initState() {  //hihi
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    if (!mounted) return;
    _navigationOption = _vietmapNavigationPlugin.getDefaultOptions();
    _navigationOption.simulateRoute = false;
    _navigationOption.apiKey =
        '96dba6f75fbade7718abd8c97f431452bdbd4d3084614145';
    _navigationOption.mapStyle =
        "https://maps.vietmap.vn/api/maps/light/styles.json?apikey=96dba6f75fbade7718abd8c97f431452bdbd4d3084614145";
    _navigationOption.trackCameraPosition = true;
    _vietmapNavigationPlugin.setDefaultOptions(_navigationOption);
  }

  Future<void> searchLocation(String query, bool isPickup) async {
    if (query.isEmpty) return;

    var result = await Vietmap.autocomplete(
        VietMapAutoCompleteParams(textSearch: query));

    result.fold(
      (failure) => setState(() {
        if (isPickup) {
          _pickupResults = [];
        } else {
          _dropoffResults = [];
        }
      }),
      (data) => setState(() {
        if (isPickup) {
          _pickupResults = data;
        } else {
          _dropoffResults = data;
        }
      }),
    );
  }

  Future<LatLng?> getCoordinates(String refId) async {
    var result = await Vietmap.place(refId);
    return result.fold(
      (failure) => null,
      (data) => LatLng(
          data.latitude?.toDouble() ?? 0.0, data.longitude?.toDouble() ?? 0.0),
    );
  }

  void buildRoute() {
    if (pickupLocation != null && dropoffLocation != null) {
      _mapController?.buildRoute(
        waypoints: [pickupLocation!, dropoffLocation!],
        profile: DrivingProfile.drivingTraffic,
      );
      setState(() {
        distance = (LatLng latLng, LatLng latLng2) {}(
            pickupLocation!, dropoffLocation!);
        price = calculatePrice(distance);
      });
    }
  }

  @override
  void dispose() {
    _mapController?.onDispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Ô tìm kiếm điểm đón
                TextField(
                  controller: _pickupController,
                  decoration: InputDecoration(
                    hintText: 'Nhập điểm đón...',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () =>
                          searchLocation(_pickupController.text, true),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Ô tìm kiếm điểm trả
                TextField(
                  controller: _dropoffController,
                  decoration: InputDecoration(
                    hintText: 'Nhập điểm trả...',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () =>
                          searchLocation(_dropoffController.text, false),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                NavigationView(
                  mapOptions: _navigationOption,
                  onMapCreated: (controller) {
                    _mapController = controller as VietmapController?;
                  },
                ),
              ],
            ),
          ),
          // Hiển thị kết quả tìm kiếm và thông tin chi tiết
          if (_pickupResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _pickupResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_pickupResults[index].name ?? 'Không có tên'),
                    subtitle: Text(
                        _pickupResults[index].address ?? 'Không có địa chỉ'),
                    onTap: () async {
                      var selectedPlace = _pickupResults[index];
                      pickupLocation =
                          await getCoordinates(selectedPlace.refId ?? '');
                      if (pickupLocation != null) {
                        _pickupController.text = selectedPlace.name ?? '';
                        setState(() => _pickupResults.clear());
                      }
                    },
                  );
                },
              ),
            ),
          if (_dropoffResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _dropoffResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_dropoffResults[index].name ?? 'Không có tên'),
                    subtitle: Text(
                        _dropoffResults[index].address ?? 'Không có địa chỉ'),
                    onTap: () async {
                      var selectedPlace = _dropoffResults[index];
                      dropoffLocation =
                          await getCoordinates(selectedPlace.refId ?? '');
                      if (dropoffLocation != null) {
                        _dropoffController.text = selectedPlace.name ?? '';
                        setState(() => _dropoffResults.clear());
                        buildRoute(); // Tạo tuyến đường
                      }
                    },
                  );
                },
              ),
            ),

          // Thông tin chi tiết sau khi tìm được điểm đón và điểm trả
          if (pickupLocation != null && dropoffLocation != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Khoảng cách: ${distance.toStringAsFixed(2)} km'),
                  Text('Giá tiền: ${price.toStringAsFixed(0)} VNĐ'),
                  DropdownButton<String>(
                    value: vehicleType,
                    items: ['Xe 4 Chỗ', 'Xe 7 Chỗ'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        vehicleType = newValue!;
                        passengerCount = (vehicleType == 'Xe 4 Chỗ') ? 4 : 7;
                      });
                    },
                  ),
                  Text('Loại xe: $vehicleType'),
                  Text('Số lượng người: $passengerCount người'),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(hintText: 'Ghi chú (nếu có)'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Xử lý khi nhấn Tiếp tục (ví dụ: đi đến màn hình tiếp theo)
                    },
                    child: const Text('Tiếp tục'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  double calculatePrice(double distance) {}
}

extension on VietmapController? {
  void buildRoute(
      {required List<LatLng> waypoints, required DrivingProfile profile}) {}

  void onDispose() {}
}

extension on VietmapPlaceModel {
  get latitude => null;

  get longitude => null;
}
