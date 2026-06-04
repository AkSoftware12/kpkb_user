import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Themes/colors.dart';
import '../../../../baseurlp/baseurl.dart';
import '../../../../bean/address.dart';
import 'addaddresspage.dart';
import 'addaddresspage_manual.dart';
import 'editaddresspage.dart';

class SavedAddressesPage extends StatelessWidget {
  final dynamic vendorId;
  final VoidCallback onReturn;

  const SavedAddressesPage(
      this.vendorId, {
        super.key,
        required this.onReturn,
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        centerTitle: true,
        title:  Text(
          'Saved Addresses',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
            fontSize: 16.sp
          ),
        ),
      ),
      body: SavedAddresses(vendorId, onReturn),
    );
  }
}

class SavedAddresses extends StatefulWidget {
  final dynamic vendorId;
  final VoidCallback onReturn;

  const SavedAddresses(this.vendorId, this.onReturn, {super.key});

  @override
  State<SavedAddresses> createState() => _SavedAddressesState();
}

class _SavedAddressesState extends State<SavedAddresses> {
  final List<ShowAddress> showAddressList = [];

  int selectedIndex = -1;
  bool isLoading = false;
  bool actionLoading = false;
  String message = '';

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    await getData();
    await getAddress();
  }

  Future<void> getData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      message = prefs.getString("message") ?? "";
    });
  }

  bool _isSelectedAddress(dynamic item) {
    try {
      final map = item.toJson();

      return map['status'].toString() == '1' ||
          map['selected'].toString() == '1' ||
          map['is_selected'].toString() == '1' ||
          map['is_default'].toString() == '1' ||
          map['default_address'].toString() == '1';
    } catch (_) {
      return item.status.toString() == '1';
    }
  }

  Future<void> getAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('user_id');

    if (userId == null) {
      _showToast('User not found. Please login again.');
      return;
    }

    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final response = await http.post(
        Uri.parse(showAddress),
        body: {'user_id': userId.toString()},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'].toString() == "1") {
          final List data = jsonData['data'] ?? [];

          final list = data.map((e) => ShowAddress.fromJson(e)).toList();

          setState(() {
            showAddressList
              ..clear()
              ..addAll(list);

            selectedIndex = showAddressList.indexWhere(_isSelectedAddress);

            isLoading = false;
          });
        } else {
          setState(() {
            showAddressList.clear();
            selectedIndex = -1;
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
        _showToast('No address found!');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> selectAddressd(dynamic addressId, int index) async {
    if (addressId == null) {
      _showToast('Invalid address');
      return;
    }

    setState(() {
      selectedIndex = index;
      actionLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(selectAddress),
        body: {'address_id': addressId.toString()},
      );

      if (!mounted) return;

      final jsonData =
      response.statusCode == 200 ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 &&
          jsonData['status'].toString() == "1") {
        widget.onReturn();

        setState(() => actionLoading = false);

        Navigator.pop(context);
      } else {
        setState(() => actionLoading = false);
        _showToast(jsonData['message']?.toString() ?? 'Unable to select address');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => actionLoading = false);
      _showToast('Please try again!');
    }
  }

  Future<void> deleteAddress(dynamic addressId) async {
    if (addressId == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Delete Address?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: kMainColor, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => actionLoading = true);

    try {
      final response = await http.post(
        Uri.parse(removeAddress),
        body: {'address_id': addressId.toString()},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        await getAddress();
      } else {
        _showToast('Unable to delete address');
      }
    } catch (e) {
      _showToast('Please try again!');
    } finally {
      if (mounted) setState(() => actionLoading = false);
    }
  }

  Future<void> _showAddAddressPopup() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          // margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          padding: const EdgeInsets.fromLTRB(10,10,10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // Drag handle
              Container(
                height: 5,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),


              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 50.sp,
                    width: 50.sp,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          kButtonColor.withOpacity(.18),
                          kButtonColor.withOpacity(.06),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Icon(
                        Icons.add_location_alt_rounded,
                        color: kButtonColor,
                        size: 25.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.sp,),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                        'Add Delivery Address',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),


                      // Subtitle
                      Text(
                        'Choose how you want to add your address.',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12.sp,
                          height: 1.4,
                        ),
                      ),

                    ],
                  )

                ],
              ),
              SizedBox(height: 14.sp),


              Divider(
                height: 2.sp,
                color: Colors.grey,
              ),

              // Top Icon


               SizedBox(height: 15.sp),

              // Manual + Auto Buttons
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    /// MANUAL ADDRESS
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () async {
                          Navigator.pop(context);

                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddAddressPageManual(widget.vendorId),
                            ),
                          );

                          if (mounted) {
                            getAddress();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: kButtonColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1.4,
                            ),
                          ),
                          child: Column(
                            children: [

                              Container(
                                height: 50.sp,
                                width: 50.sp,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child:  Icon(
                                  Icons.edit_location_alt_rounded,
                                  size: 25.sp,
                                  color: Colors.black87,
                                ),
                              ),

                              const SizedBox(height: 10),

                               Text(
                                "Manual",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                "Enter address manually",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  height: 1.3,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// AUTO ADDRESS / MAP
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () async {
                          Navigator.pop(context);

                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddAddressPage(widget.vendorId),
                            ),
                          );

                          if (mounted) {
                            getAddress();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                kButtonColor,
                                kButtonColor.withOpacity(.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: kButtonColor.withOpacity(.35),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [

                              Container(
                                height: 50.sp,
                                width: 50.sp,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.20),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child:  Icon(
                                  Icons.my_location_rounded,
                                  size: 25.sp,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 14),

                               Text(
                                "Auto",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 4),

                               Text(
                                "Pick from map location",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  height: 1.3,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

               SizedBox(height: 50.sp),

            ],
          ),
        );
      },
    );
  }



  Future<void> _openEditAddress(ShowAddress item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditAddresspage(
          item.lat,
          item.lng,
          item.pincode,
          item.houseno,
          item.street,
          item.state,
          item.address_id,
          widget.vendorId,
          item.city_id,
          item.area_id,
          item.type ?? 'Other',
        ),
      ),
    );

    if (mounted) getAddress();
  }

  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: kMainColor,
      textColor: Colors.white,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          color: kButtonColor,
          onRefresh: getAddress,
          child: isLoading
              ? const _SingleAddressLoader()
              : showAddressList.isEmpty
              ? _EmptyAddressView(
            message: message,
            onAdd: _showAddAddressPopup,
          )
              : ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 110),
            children: [
              _HeaderCard(total: showAddressList.length),
              const SizedBox(height: 14),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: showAddressList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = showAddressList[index];

                  return _AddressCard(
                    item: item,
                    selected: selectedIndex == index,
                    onSelect: () {
                      selectAddressd(item.address_id, index);
                    },
                    onEdit: () => _openEditAddress(item),
                    onDelete: () => deleteAddress(item.address_id),
                  );
                },
              ),
            ],
          ),
        ),

        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            child: SizedBox(
              height: 45.sp,
              child: ElevatedButton.icon(
                onPressed: _showAddAddressPopup,
                icon: const Icon(Icons.add_location_alt_rounded),
                label:  Text(
                  "Add New Address",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kButtonColor,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: kMainColor.withOpacity(.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ),

        if (actionLoading) const _FullScreenLoader(),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final int total;

  const _HeaderCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(width: 1,color: Colors.grey.shade300)
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.location_on_rounded, color: Colors.black),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '$total Saved Addresses',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final ShowAddress item;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.item,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String type =
    item.type == null || item.type.toString().trim().isEmpty
        ? 'Other'
        : item.type.toString();

    final String address = item.address?.toString() ?? '';

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? kButtonColor.withOpacity(.06) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? kButtonColor : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, color: kButtonColor, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                address.isEmpty ? 'Address not available' : address,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: selected,
              activeColor: kButtonColor,
              onChanged: (_) => onSelect(),
            ),
            // IconButton(
            //   icon: Icon(Icons.edit_rounded, color: kButtonColor),
            //   onPressed: onEdit,
            // ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyAddressView extends StatelessWidget {
  final String message;
  final VoidCallback onAdd;

  const _EmptyAddressView({
    required this.message,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 120),
      children: [
        Center(
          child: Text(
            message.trim().isEmpty ? 'No address found' : message,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _SingleAddressLoader extends StatelessWidget {
  const _SingleAddressLoader();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              CircularProgressIndicator(color: kButtonColor),
              const SizedBox(height: 16),
              const Text(
                'Fetching address...',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FullScreenLoader extends StatelessWidget {
  const _FullScreenLoader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(.25),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: kButtonColor),
            const SizedBox(width: 16),
            const Text(
              'Loading...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}