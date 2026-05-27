import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:flutter_google_places_hoc081098/google_maps_webservice_places.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Components/custom_appbar.dart';
import '../../Themes/colors.dart';
import '../../Themes/constantfile.dart';
import '../../bean/latlng.dart';

class LocationPage extends StatelessWidget {
  final dynamic lat;
  final dynamic lng;

  const LocationPage(this.lat, this.lng, {super.key});

  @override
  Widget build(BuildContext context) {
    return SetLocation(
      lat: lat is double ? lat : double.tryParse(lat?.toString() ?? ''),
      lng: lng is double ? lng : double.tryParse(lng?.toString() ?? ''),
      apiKey: apiKey,
    );
  }
}

class SetLocation extends StatefulWidget {
  final double? lat;
  final double? lng;
  final String apiKey;

  const SetLocation({
    super.key,
    this.lat,
    this.lng,
    required this.apiKey,
  });

  @override
  State<SetLocation> createState() => _SetLocationState();
}

class _SetLocationState extends State<SetLocation> {
  double? lat;
  double? lng;

  String currentAddress = '';
  bool button = false;
  bool isLoading = false;

  late GoogleMapsPlaces _places;
  final Completer<GoogleMapController> _controller = Completer();
  final Map<MarkerId, Marker> markers = {};

  Timer? _debounce;

  static const LatLng _defaultLatLng = LatLng(28.6139, 77.2090);

  CameraPosition get _initialCameraPosition {
    return CameraPosition(
      target: LatLng(lat ?? _defaultLatLng.latitude, lng ?? _defaultLatLng.longitude),
      zoom: 14,
    );
  }

  @override
  void initState() {
    super.initState();
    lat = widget.lat;
    lng = widget.lng;
    _places = GoogleMapsPlaces(apiKey: widget.apiKey);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationFast();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();

    if (_controller.isCompleted) {
      _controller.future.then((controller) {
        controller.dispose();
      }).catchError((_) {});
    }

    super.dispose();
  }

  Future<void> _initLocationFast() async {
    final prefs = await SharedPreferences.getInstance();

    lat ??= double.tryParse(prefs.getString("lat") ?? '');
    lng ??= double.tryParse(prefs.getString("lng") ?? '');
    currentAddress = prefs.getString("full_address") ?? '';

    if (lat != null && lng != null) {
      _updateMarker(LatLng(lat!, lng!));
      await _moveCamera(lat!, lng!);

      if (currentAddress.isEmpty) {
        await _saveAddressFromLatLng(LatLng(lat!, lng!));
      } else {
        if (mounted) {
          setState(() {
            button = true;
          });
        }
      }
      return;
    }

    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return;

      Position? position = await Geolocator.getLastKnownPosition();

      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 4),
      );

      lat = position.latitude;
      lng = position.longitude;

      final selected = LatLng(lat!, lng!);

      await _saveLatLng(selected);
      _updateMarker(selected);
      await _moveCamera(lat!, lng!);
      await _saveAddressFromLatLng(selected);
    } catch (e) {
      _showToast("Location fetch failed");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<bool> _handleLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showToast("Please enable location service");
      await Geolocator.openLocationSettings();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      _showToast("Location permission denied");
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      _showToast("Enable location permission from app settings");
      await Geolocator.openAppSettings();
      return false;
    }

    return true;
  }

  Future<void> _saveLatLng(LatLng position) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("lat", position.latitude.toStringAsFixed(8));
    await prefs.setString("lng", position.longitude.toStringAsFixed(8));
  }

  Future<void> _saveAddressFromLatLng(LatLng position) async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      await _saveLatLng(position);

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = "Selected Location";
      String city = "Current Location";

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
          p.country,
        ].where((e) => e != null && e.trim().isNotEmpty).map((e) => e!).toList();

        address = parts.join(", ");

        city = p.locality?.isNotEmpty == true
            ? p.locality!
            : p.subAdministrativeArea?.isNotEmpty == true
            ? p.subAdministrativeArea!
            : p.administrativeArea?.isNotEmpty == true
            ? p.administrativeArea!
            : "Current Location";
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("city_name", city);
      await prefs.setString("full_address", address);

      if (!mounted) return;

      setState(() {
        lat = position.latitude;
        lng = position.longitude;
        currentAddress = address;
        button = true;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        currentAddress = "Selected Location";
        button = true;
        isLoading = false;
      });
    }
  }

  Future<void> _moveCamera(double lat, double lng) async {
    try {
      if (!_controller.isCompleted) return;

      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(lat, lng),
            zoom: 15,
          ),
        ),
      );
    } catch (_) {}
  }

  void _updateMarker(LatLng position) {
    if (!mounted) return;

    setState(() {
      markers[const MarkerId('location')] = Marker(
        markerId: const MarkerId('location'),
        position: position,
        icon: BitmapDescriptor.defaultMarker,
      );
    });
  }

  Future<void> getPlaces(BuildContext context) async {
    try {
      setState(() {
        button = false;
        isLoading = true;
      });

      final Prediction? p = await PlacesAutocomplete.show(
        context: context,
        apiKey: widget.apiKey,
        onError: onError,
        mode: Mode.overlay,
        language: 'en',
        components: [Component(Component.country, 'in')],
      );

      if (p != null) {
        await displayPrediction(p);
      }
    } catch (e) {
      _showToast("Place search failed");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void onError(PlacesAutocompleteResponse response) {
    _showToast(response.errorMessage ?? 'Something went wrong');
  }

  Future<void> displayPrediction(Prediction p) async {
    if (p.placeId == null) {
      _showToast("Invalid place selected");
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final places = GoogleMapsPlaces(
        apiKey: widget.apiKey,
        apiHeaders: await GoogleApiHeaders().getHeaders(),
      );

      final detail = await places.getDetailsByPlaceId(p.placeId!);

      final selectedLat = detail.result.geometry?.location.lat;
      final selectedLng = detail.result.geometry?.location.lng;

      if (selectedLat == null || selectedLng == null) {
        _showToast("Unable to fetch selected location");
        return;
      }

      final selected = LatLng(selectedLat, selectedLng);

      lat = selectedLat;
      lng = selectedLng;

      _updateMarker(selected);
      await _moveCamera(selectedLat, selectedLng);
      await _saveAddressFromLatLng(selected);
    } catch (e) {
      _showToast("Location details failed");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _onCameraMove(CameraPosition position) {
    lat = position.target.latitude;
    lng = position.target.longitude;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _updateMarker(position.target);
    });
  }

  void _onCameraIdle() {
    if (lat == null || lng == null) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _saveAddressFromLatLng(LatLng(lat!, lng!));
    });
  }

  void _continueLocation() {
    if (lat == null || lng == null) {
      _showToast("Please select a valid location");
      return;
    }

    Navigator.pop(context, BackLatLng(lat!, lng!));
  }

  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 14,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(112),
        child: CustomAppBar(
          titleWidget: Text(
            'Set delivery location',
            style: TextStyle(
              fontSize: 16.7,
              color: black_color,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: IconButton(
                icon: Icon(Icons.my_location, color: kMainColor),
                iconSize: 30,
                onPressed: _getCurrentLocation,
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size(MediaQuery.of(context).size.width * 0.88, 52),
            child: GestureDetector(
              onTap: () => getPlaces(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.88,
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 24, color: kMainColor),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Search delivery location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _initialCameraPosition,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  buildingsEnabled: false,
                  markers: markers.values.toSet(),
                  onMapCreated: (GoogleMapController controller) async {
                    if (!_controller.isCompleted) {
                      _controller.complete(controller);
                    }

                    if (lat != null && lng != null) {
                      final selected = LatLng(lat!, lng!);
                      _updateMarker(selected);
                      await _moveCamera(lat!, lng!);
                    }
                  },
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                ),

                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 42),
                    child: Icon(
                      Icons.location_pin,
                      size: 44,
                      color: kMainColor,
                    ),
                  ),
                ),

                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.08),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: kMainColor, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Move map pin to select exact delivery location",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (isLoading)
                  Container(
                    color: Colors.black.withOpacity(.06),
                    child: Center(
                      child: CircularProgressIndicator(color: kMainColor),
                    ),
                  ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 18,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: kMainColor.withOpacity(.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.location_on_rounded, color: kMainColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currentAddress.isNotEmpty
                            ? currentAddress
                            : 'Fetching selected location...',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: button ? kMainColor : Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: button ? 4 : 0,
                    ),
                    onPressed: button ? _continueLocation : null,
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Uuid {
  final Random _random = Random();

  String generateV4() {
    final int special = 8 + _random.nextInt(4);
    return '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}-'
        '${_bitsDigits(16, 4)}-'
        '4${_bitsDigits(12, 3)}-'
        '${_printDigits(special, 1)}${_bitsDigits(12, 3)}-'
        '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}';
  }

  String _bitsDigits(int bitCount, int digitCount) =>
      _printDigits(_generateBits(bitCount), digitCount);

  int _generateBits(int bitCount) => _random.nextInt(1 << bitCount);

  String _printDigits(int value, int count) =>
      value.toRadixString(16).padLeft(count, '0');
}