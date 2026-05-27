import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../../../Components/custom_appbar.dart';
import '../../../../Themes/colors.dart';
import '../../../../Themes/constantfile.dart';
import '../../../../baseurlp/baseurl.dart';
import '../../../../bean/address.dart';

class AddAddressPageManual extends StatefulWidget {
  final dynamic vendorId;

  const AddAddressPageManual(this.vendorId, {Key? key}) : super(key: key);

  @override
  State<AddAddressPageManual> createState() => AddAddressState();
}

class AddAddressState extends State<AddAddressPageManual> {
  final pincodeController = TextEditingController();
  final stateController = TextEditingController();
  final houseno = TextEditingController();
  final city = TextEditingController();

  List<CityList> cityListt = [];
  List<AreaList> areaList = [];
  List<String> addressTyp = ['Home', 'Office', 'Other'];

  String selectCity = 'Dehradun';
  String addressType = 'Select address type';
  String selectArea = 'Select near by area';

  bool showDialogBox = false;
  dynamic selectAreaId;
  dynamic selectCityId;

  double? lat = 0.0;
  double? lng = 0.0;

  bool houseError = false;
  bool stateError = false;
  bool pincodeError = false;
  bool addressTypeError = false;
  bool cityError = false;

  bool isPincodeLoading = false;
  String _lastLookedUpPin = '';

  final Completer<GoogleMapController> _controller = Completer();

  @override
  void initState() {
    super.initState();
    getdata();
    getCityList();
    pincodeController.addListener(_onPincodeChanged);
  }

  @override
  void dispose() {
    pincodeController.removeListener(_onPincodeChanged);
    pincodeController.dispose();
    stateController.dispose();
    houseno.dispose();
    city.dispose();
    super.dispose();
  }

  void _onPincodeChanged() {
    final pin = pincodeController.text.trim();

    if (pin.length < 6) {
      _lastLookedUpPin = '';
      stateController.clear();
      city.clear();

      setState(() {
        selectCity = 'Dehradun';
        selectCityId = null;
        cityError = false;
        stateError = false;
        pincodeError = false;
        areaList.clear();
        selectArea = 'Select near by area';
        selectAreaId = '';
      });
      return;
    }

    if (pin.length == 6 && pin != _lastLookedUpPin) {
      _lastLookedUpPin = pin;
      _fetchCityStateFromPincode(pin);
    }
  }

  Future<void> _fetchCityStateFromPincode(String pin) async {
    setState(() => isPincodeLoading = true);

    try {
      final uri = Uri.parse('https://api.postalpincode.in/pincode/$pin');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          final first = data[0];

          if (first['Status'] == 'Success' &&
              first['PostOffice'] != null &&
              (first['PostOffice'] as List).isNotEmpty) {
            final postOffice = first['PostOffice'][0];

            final String stateName = postOffice['State'] ?? '';
            final String cityName =
                postOffice['District'] ?? postOffice['Region'] ?? '';

            setState(() {
              stateController.text = stateName;
              city.text = cityName;
              stateError = false;
              pincodeError = false;
            });

            _matchOnlyDehradun(cityName);
          } else {
            _clearPinData();

            Fluttertoast.showToast(
              msg: "Invalid PIN code",
              backgroundColor: Colors.black,
              textColor: Colors.white,
            );
          }
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "PIN code check nahi ho pa raha",
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => isPincodeLoading = false);
      }
    }
  }

  void _clearPinData() {
    setState(() {
      stateController.clear();
      city.clear();
      selectCity = 'Dehradun';
      selectCityId = null;
      pincodeError = true;
      cityError = false;
      areaList.clear();
      selectArea = 'Select near by area';
      selectAreaId = '';
    });
  }

  void _matchOnlyDehradun(String cityName) {
    final pinCity = cityName.toLowerCase().trim();

    if (pinCity != 'dehradun') {
      setState(() {
        city.text = cityName;
        selectCity = cityName;
        selectCityId = null;
        cityError = true;
        areaList.clear();
        selectArea = 'Select near by area';
        selectAreaId = '';
      });

      Fluttertoast.showToast(
        msg: "Delivery only available in Dehradun",
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
      return;
    }

    CityList? matched;

    for (final c in cityListt) {
      if (c.city_name.toLowerCase().trim() == 'dehradun') {
        matched = c;
        break;
      }
    }

    setState(() {
      city.text = 'Dehradun';
      selectCity = 'Dehradun';
      selectCityId = matched?.city_id;
      cityError = false;
      areaList.clear();
      selectArea = 'Select near by area';
      selectAreaId = '';
    });

    if (matched != null) {
      getAreaList(matched.city_id);
    }
  }

  Future<void> getdata() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    lat = double.tryParse(pref.getString("lat") ?? '0.0') ?? 0.0;
    lng = double.tryParse(pref.getString("lng") ?? '0.0') ?? 0.0;
  }

  void getCityList() async {
    Uri myUri = Uri.parse(cityList);

    http.post(myUri, body: {
      'vendor_id': '${widget.vendorId}',
    }).then((value) {
      if (value.statusCode == 200) {
        var jsonData = jsonDecode(value.body);

        if (jsonData['status'] == "1") {
          var tagObjsJson = jsonData['data'] as List;
          List<CityList> tagObjs =
          tagObjsJson.map((e) => CityList.fromJson(e)).toList();

          setState(() {
            cityListt.clear();
            cityListt = tagObjs;
          });

          if (city.text.trim().isNotEmpty) {
            _matchOnlyDehradun(city.text.trim());
          }
        }
      }
    });
  }

  void getAreaList(dynamic city_id) async {
    Uri myUri = Uri.parse(areaLists);

    http.post(myUri, body: {
      'vendor_id': '${widget.vendorId}',
      'city_id': '$city_id',
    }).then((value) {
      if (value.statusCode == 200) {
        var jsonData = jsonDecode(value.body);

        if (jsonData['status'] == "1") {
          var tagObjsJson = jsonData['data'] as List;
          List<AreaList> tagObjs =
          tagObjsJson.map((e) => AreaList.fromJson(e)).toList();

          setState(() {
            areaList.clear();
            areaList = tagObjs;
          });
        }
      }
    });
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    bool error = false,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      counterText: '',
      prefixIcon: Icon(icon, color: kButtonColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: error ? Colors.red : Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: error ? Colors.red : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: kButtonColor, width: 1.5),
      ),
    );
  }

  Widget _errorText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 5),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.red,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: CustomAppBar(
          color: Colors.white,
          titleWidget: const Text(
            'Add Address',
            style: TextStyle(
              fontSize: 17,
              color: Colors.black,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: const [],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 100),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title("PIN Code"),
              TextField(
                controller: pincodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: _inputDecoration(
                  hint: "Enter 6 digit PIN code",
                  icon: Icons.pin_drop_rounded,
                  error: pincodeError,
                  suffixIcon: isPincodeLoading
                      ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                      : null,
                ),
              ),
              if (pincodeError) _errorText("Enter valid PIN code"),

              const SizedBox(height: 14),

              _title("City"),
              TextField(
                controller: city,
                readOnly: true,
                decoration: _inputDecoration(
                  hint: "City auto fill from PIN",
                  icon: Icons.location_city_rounded,
                  error: cityError,
                ),
              ),
              if (cityError) _errorText("Delivery only available in Dehradun"),

              const SizedBox(height: 14),

              _title("State"),
              TextField(
                controller: stateController,
                readOnly: true,
                decoration: _inputDecoration(
                  hint: "State auto fill from PIN",
                  icon: Icons.map_rounded,
                  error: stateError,
                ),
              ),
              if (stateError) _errorText("Enter state"),

              const SizedBox(height: 14),

              _title("Address Type"),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: addressTypeError ? Colors.red : Colors.grey.shade300,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Icon(Icons.home_work_rounded, color: kButtonColor),
                          const SizedBox(width: 12),
                          Text(addressType),
                        ],
                      ),
                    ),
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(16),
                    items: addressTyp.map((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        addressType = value!;
                        addressTypeError = false;
                      });
                    },
                  ),
                ),
              ),
              if (addressTypeError) _errorText("Select address type"),

              const SizedBox(height: 14),

              _title("Full Address"),
              TextField(
                controller: houseno,
                keyboardType: TextInputType.multiline,
                maxLines: 10,
                minLines: 2,
                onChanged: (value) {
                  if (houseError && value.trim().isNotEmpty) {
                    setState(() => houseError = false);
                  }
                },
                decoration: _inputDecoration(
                  hint: "House no, Flat, Building, Street...",
                  icon: Icons.home_rounded,
                  error: houseError,
                ),
              ),
              if (houseError) _errorText("Enter full address"),

              const SizedBox(height: 50),

              GestureDetector(
                onTap: showDialogBox ? null : _validateAndSave,
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    gradient: LinearGradient(
                      colors: [
                        kButtonColor,
                        kButtonColor.withOpacity(.75),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kButtonColor.withOpacity(.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: showDialogBox
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    'Save Address',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: kWhiteColor,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _validateAndSave() {
    if (pincodeController.text.trim().length != 6) {
      setState(() => pincodeError = true);
      Fluttertoast.showToast(msg: "Enter valid PIN code");
      return;
    }

    if (city.text.trim().toLowerCase() != 'dehradun') {
      setState(() => cityError = true);
      Fluttertoast.showToast(msg: "Delivery only available in Dehradun");
      return;
    }

    if (selectCityId == null || '$selectCityId'.isEmpty) {
      setState(() => cityError = true);
      Fluttertoast.showToast(msg: "Dehradun city service not found");
      return;
    }

    if (stateController.text.trim().isEmpty) {
      setState(() => stateError = true);
      Fluttertoast.showToast(msg: "Enter state");
      return;
    }

    if (addressType == 'Select address type') {
      setState(() => addressTypeError = true);
      Fluttertoast.showToast(msg: "Select address type");
      return;
    }

    if (houseno.text.trim().isEmpty) {
      setState(() => houseError = true);
      Fluttertoast.showToast(msg: "Enter full address");
      return;
    }

    setState(() => showDialogBox = true);

    addAddres(
      selectAreaId,
      selectCityId,
      houseno.text.trim(),
      '',
      // houseno.text.trim(),
      pincodeController.text.trim(),
      stateController.text.trim(),
      context,
    );
  }

  void addAddres(
      dynamic area_id,
      dynamic city_id,
      String house_no,
      String street,
      String pincode,
      String state,
      BuildContext context,
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    Uri myUri = Uri.parse(addAddress);

    http.post(myUri, body: {
      'user_id': '${prefs.getInt('user_id')}',
      'user_name': '${prefs.getString('user_name')}',
      'user_number': '${prefs.getString('user_phone')}',
      'city_id': '$city_id',
      'houseno': house_no,
      // 'street': street,
      'street': '',
      'state': state,
      'pin': pincode,
      'lat': '$lat',
      'lng': '$lng',

      'address_type': addressType,
    }).then((value) {
      debugPrint('Address Response: ${value.body}');

      if (value.statusCode == 200) {
        var jsonData = jsonDecode(value.body);

        if (jsonData['status'] == "1") {
          prefs.setString("area_id", "$area_id");
          prefs.setString("city_id", "$city_id");

          setState(() => showDialogBox = false);

          Fluttertoast.showToast(msg: "Address saved successfully");
          Navigator.pop(context);
        } else {
          setState(() => showDialogBox = false);
          Fluttertoast.showToast(
            msg: jsonData['message']?.toString() ?? "Address save failed",
          );
        }
      } else {
        setState(() => showDialogBox = false);
        Fluttertoast.showToast(msg: "Server error");
      }
    }).catchError((e) {
      setState(() => showDialogBox = false);
      Fluttertoast.showToast(msg: "Something went wrong");
      debugPrint(e.toString());
    });
  }
}