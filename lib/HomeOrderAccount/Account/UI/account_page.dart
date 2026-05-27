import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../Auth/login_navigator.dart';
import '../../../Routes/routes.dart';
import '../../../Themes/colors.dart';
import '../../../baseurlp/baseurl.dart';
import 'ListItems/saved_addresses_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  static const Color bgColor = Color(0xffF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: white_color,
        automaticallyImplyLeading: true,
        title:  Text(
          'my_account'.tr(),
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: const Account(),

    );
  }
}

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  String userName = '';
  String phoneNumber = '';
  String emailId = '';
  String message = '';



  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      userName = prefs.getString('user_name') ?? '';
      phoneNumber = prefs.getString('user_phone') ?? '';
      emailId = prefs.getString('user_email') ?? '';
      message = prefs.getString("message") ?? '';
    });
  }

  Widget creditLimitCard() {
    return FutureBuilder(
      future: SharedPreferences.getInstance().then((prefs) {
        int userId = prefs.getInt("user_id") ?? 0;

        return http.post(
          Uri.parse(
            "$creditLimit$userId",
          ),
        );
      }),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.all(5),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.black,
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final response = snapshot.data?.body != null
            ? jsonDecode(snapshot.data!.body)
            : {};

        final user = response['user'] ?? {};
        final rank = user['rank'];

        final monthlyRemaining =
            response['monthly_gst_remaining'] ?? 0;

        final annualRemaining =
            response['annual_gst_remaining'] ?? 0;

        final monthlyLimit = rank['limit_m'] ?? 0;
        final annualLimit = rank['limit_y'] ?? 0;

        String userName = user['user_name']?.toString() ?? "";
        String userPhone = user['user_phone']?.toString() ?? "";
        String userImage = user['user_image']?.toString() ?? "";

        return Column(
          children: [
            _UserProfileCard(
              name: userName,
              phone: userPhone,
              userImage: userImage,
              onEditImage: () {
                _openImageUpdateSheet();
              },
            ),
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.15),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  width: 1,
                  color: Colors.grey.shade400,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [


                  Row(
                    children: [

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.credit_score,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              "GST Credit Limit",
                              style: TextStyle(
                                color: Colors.black.withOpacity(.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          "${rank['title']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                "Monthly Remaining",
                                style: TextStyle(
                                  color: Colors.black.withOpacity(.7),
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                "₹$monthlyRemaining",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                "Limit ₹$monthlyLimit",
                                style: TextStyle(
                                  color: Colors.black.withOpacity(.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Text(
                                "Annual Remaining",
                                style: TextStyle(
                                  color: Colors.black.withOpacity(.7),
                                  fontSize: 13,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                "₹$annualRemaining",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                "Limit ₹$annualLimit",
                                style: TextStyle(
                                  color: Colors.black.withOpacity(.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  File? selectedProfileImage;
  bool isImageUpdating = false;

  Future<void> _openImageUpdateSheet() async {
    selectedProfileImage = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.all(18.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  Container(
                    width: 45.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),

                  SizedBox(height: 18.h),

                  Text(
                    "Update Profile Image",
                    style: TextStyle(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),

                  SizedBox(height: 22.h),

                  Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 48.r,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: selectedProfileImage != null
                          ? FileImage(selectedProfileImage!)
                          : null,
                      child: selectedProfileImage == null
                          ? Icon(
                        Icons.person,
                        size: 45.sp,
                        color: Colors.black54,
                      )
                          : null,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16.r),
                          onTap: () async {
                            await _pickProfileImage(
                              ImageSource.camera,
                              setSheetState,
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: kButtonColor,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.camera_alt_rounded,
                                  color: kButtonColor,
                                  size: 24.sp,
                                ),

                                SizedBox(height: 2.h),

                                Text(
                                  "Camera",
                                  style: TextStyle(
                                    color: kButtonColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 14.w),

                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16.r),
                          onTap: () async {
                            await _pickProfileImage(
                              ImageSource.gallery,
                              setSheetState,
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: kButtonColor,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.photo_library_rounded,
                                  color: kButtonColor,
                                  size: 24.sp,
                                ),

                                SizedBox(height: 2.h),

                                Text(
                                  "Gallery",
                                  style: TextStyle(
                                    color: kButtonColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  SizedBox(
                    width: double.infinity,
                    height: 40.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kButtonColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      onPressed: isImageUpdating
                          ? null
                          : () async {
                        await _updateProfileImage(sheetContext);
                      },
                      child: isImageUpdating
                          ? SizedBox(
                        height: 22.r,
                        width: 22.r,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        "Update".toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickProfileImage(
      ImageSource source,
      StateSetter setSheetState,
      ) async {
    final ImagePicker picker = ImagePicker();

    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      setSheetState(() {
        selectedProfileImage = File(pickedFile.path);
      });
    }
  }


  Future<void> _updateProfileImage(BuildContext sheetContext) async {
    if (selectedProfileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select image")),
      );
      return;
    }

    try {
      setState(() => isImageUpdating = true);

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id") ?? 0;

      var request = http.MultipartRequest(
        "POST",
        Uri.parse(userUpdate),
      );

      request.fields["user_id"] = userId.toString();

      request.files.add(
        await http.MultipartFile.fromPath(
          "photo", // ✅ API key
          selectedProfileImage!.path,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      final data = jsonDecode(responseBody);

      if (response.statusCode == 200 && data["status"] == 1) {
        final String newImage = data["user"]["user_image"] ?? "";

        await prefs.setString("user_image", newImage);

        Navigator.pop(sheetContext);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Image updated")),
        );

        // await getUserProfile(); // ✅ account screen refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Update failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isImageUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kMainColor,
      onRefresh: _loadUser,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 80.h),
        children: [


          // SizedBox(height: 8.h),
          creditLimitCard(),


          _SectionTitle(title: "my_activity".tr()),

          _AccountTile(
            icon: Icons.location_on_rounded,
            title: "saved_addresses".tr(),
            subtitle: "manage_delivery_addresses".tr(),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SavedAddressesPage("", onReturn: () {}),
                ),
              );
            },
          ),

          _OrdersExpansionTile(),

          _AccountTile(
            icon: Icons.notifications_rounded,
            title: "notification".tr(),
            subtitle: "view_latest_offers".tr(),
            onTap: () {
              Navigator.pushNamed(context, PageRoutes.offers);
            },
          ),

          _AccountTile(
            icon: Icons.language,
            title: "change_language".tr(),
            subtitle: "change_app_language".tr(),
            onTap: () {
              showLanguagePopup(context);
            },
          ),


          SizedBox(height: 8.h),
          _SectionTitle(title: "more".tr()),
          _AccountTile(
            icon: Icons.privacy_tip_rounded,
            title: "privacy".tr(),
            subtitle: "privacy_subtext".tr(),
            onTap: () async {
              final Uri url = Uri.parse(
                'https://www.termsfeed.com/live/b710c701-5a4c-4746-88eb-77642222bf25',
              );

              await launchUrl(
                url,
                mode: LaunchMode.externalApplication,
              );
            },
          ),

          _AccountTile(
            icon: Icons.description_rounded,
            title: "terms_conditions".tr(),
            subtitle: "read_policies".tr(),
            onTap: () {
              Navigator.pushNamed(context, PageRoutes.tncPage);
            },
          ),
          _AccountTile(
            icon: Icons.receipt_long,
            title: "gst".tr(),
            subtitle: "GST rules aur tax information",
            onTap: () async {
              const url = 'https://yourdomain.com/gst-policy.pdf';

              if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
              );
              }            },
          ),
          _AccountTile(
            icon: Icons.support_agent_rounded,
            title: "support".tr(),
            subtitle: "need_help_support".tr(),
            onTap: () {
              Navigator.pushNamed(
                context,
                PageRoutes.supportPage,
                arguments: phoneNumber,
              );
            },
          ),

          _AccountTile(
            icon: Icons.info_rounded,
            title: "about_us".tr(),
            subtitle: "know_more_about_us".tr(),
            onTap: () {
              Navigator.pushNamed(context, PageRoutes.aboutUsPage);
            },
          ),

          _AccountTile(
            icon: Icons.settings_rounded,
            title: "settings".tr(),
            subtitle: "app_preferences".tr(),
            onTap: () {
              Navigator.pushNamed(context, PageRoutes.settings);
            },
          ),

          _AccountTile(
            icon: Icons.logout_rounded,
            title: "logout".tr(),
            subtitle: "logout_account".tr(),
            iconColor: Colors.red,
            bgColor: Colors.red.withOpacity(0.08),
            onTap: () => _showLogoutDialog(context),
          ),

          if (message.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }
  void showLanguagePopup(BuildContext context) {
    Locale selectedLocale = context.locale;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentLang = context.locale.languageCode;
            final selectedLang = selectedLocale.languageCode;

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 55,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Container(
                    padding:  EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kButtonColor.withOpacity(.1),
                    ),
                    child:  Icon(
                      Icons.language_rounded,
                      size: 34,
                      color: kButtonColor,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    currentLang == 'hi' ? "भाषा चुनें" : "Choose Language",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    currentLang == 'hi'
                        ? "भाषा चुनकर नीचे बटन दबाएं"
                        : "Select language and tap button",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 26),

                  _languageTile(
                    title: "English",
                    subtitle: "Use app in English",
                    shortName: "EN",
                    shortColor: Colors.blue,
                    isSelected: selectedLang == 'en',
                    onTap: () {
                      setSheetState(() {
                        selectedLocale = const Locale('en');
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  _languageTile(
                    title: "हिंदी",
                    subtitle: "ऐप हिंदी में उपयोग करें",
                    shortName: "हि",
                    shortColor: Colors.orange,
                    isSelected: selectedLang == 'hi',
                    onTap: () {
                      setSheetState(() {
                        selectedLocale = const Locale('hi');
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kButtonColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        await context.setLocale(selectedLocale);
                        Navigator.pop(sheetContext);
                        Phoenix.rebirth(context);
                      },
                      child: Text(
                        currentLang == 'hi'
                            ? "भाषा बदलें"
                            : "Apply Language",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _languageTile({
    required String title,
    required String subtitle,
    required String shortName,
    required Color shortColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? kButtonColor : Colors.grey.shade300,
            width: 1.5,
          ),
          color: isSelected ? kButtonColor.withOpacity(.08) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: shortColor.withOpacity(.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  shortName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: shortColor,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),


            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected ? kButtonColor : Colors.grey,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 62.r,
                  width: 62.r,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 34.sp,
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  "Logout?",
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Are you sure you want to logout?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 22.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text("No"),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();

                          if (!context.mounted) return;
                          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => LoginNavigator(),
                            ),
                                (Route<dynamic> route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text("Yes"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UserProfileCard extends StatelessWidget {
  final String name;
  final String phone;
  final String userImage;
  final VoidCallback onEditImage;

  const _UserProfileCard({
    required this.name,
    required this.phone,
    required this.userImage,
    required this.onEditImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(5.w, 5.h, 5.w, 5.h),
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(width: 1, color: Colors.grey.shade400),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                height: 68.r,
                width: 68.r,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: userImage.trim().isNotEmpty
                      ? Image.network(
                    userImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person_rounded,
                        color: Colors.grey,
                        size: 38.sp,
                      );
                    },
                  )
                      : Icon(
                    Icons.person_rounded,
                    color: Colors.grey,
                    size: 38.sp,
                  ),
                ),
              ),

              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: onEditImage,
                  child: Container(
                    height: 26.r,
                    width: 26.r,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: kButtonColor, width: 2),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: kButtonColor,
                      size: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(width: 14.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.trim().isEmpty ? "Guest User" : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5.h),
                if (phone.trim().isNotEmpty)
                  _ProfileInfo(icon: Icons.call_rounded, text: phone),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _ProfileInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ProfileInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 3.h),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: Colors.black.withOpacity(0.90)),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black.withOpacity(0.90),
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 5.h, 5.w, 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;
  final Color bgColor;

   _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = const Color(0xFF06087A),
    this.bgColor = const Color(0xfff5f6f5),
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            child: Row(
              children: [
                Container(
                  height: 44.r,
                  width: 44.r,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(icon, color: iconColor, size: 24.sp),
                ),
                SizedBox(width: 13.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15.sp,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrdersExpansionTile extends StatefulWidget {
  @override
  State<_OrdersExpansionTile> createState() => _OrdersExpansionTileState();
}

class _OrdersExpansionTileState extends State<_OrdersExpansionTile>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;

  static const Color mainGreen = Color(0xFF06087A);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18.r),
            onTap: () {
              setState(() => isExpanded = !isExpanded);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
              child: Row(
                children: [
                  Container(
                    height: 44.r,
                    width: 44.r,
                    decoration: BoxDecoration(
                      color: mainGreen.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Icon(
                      Icons.shopping_bag_rounded,
                      color: mainGreen,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 13.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "orders".tr(),
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          "track_orders".tr(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade500,
                      size: 26.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
              child: Column(
                children: [
                  Divider(color: Colors.grey.shade200),
                  _MiniOrderTile(
                    icon: Icons.local_shipping_rounded,
                    title: "ongoing_orders".tr(),
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pushNamed(
                        PageRoutes.ongoingOrderPage,
                      );
                    },
                  ),
                  SizedBox(height: 8.h),
                  _MiniOrderTile(
                    icon: Icons.cancel,
                    title: "cancel_orders".tr(),
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pushNamed(
                        PageRoutes.cancelOrderPage,
                      );
                    },
                  ),
                  SizedBox(height: 8.h),
                  _MiniOrderTile(
                    icon: Icons.done_all_rounded,
                    title: "completed_orders".tr(),
                    onTap: () {

                      Navigator.of(context, rootNavigator: true).pushNamed(
                        PageRoutes.completedOrderPage,
                      );

                    },
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

class _MiniOrderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MiniOrderTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  static  Color mainGreen = kButtonColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffF6F8FA),
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: Row(
            children: [
              Icon(icon, color: mainGreen, size: 22.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14.sp,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeleteTile extends StatelessWidget {
  final String phoneNumber;

  const DeleteTile(this.phoneNumber, {super.key});

  @override
  Widget build(BuildContext context) {
    return _AccountTile(
      icon: Icons.delete_forever_rounded,
      title: 'Delete Profile',
      subtitle: 'Permanently delete your account',
      iconColor: Colors.red,
      bgColor: Colors.red.withOpacity(0.08),
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text('Delete Profile'),
              content: const Text('Are you sure?'),
              actions: [
                TextButton(
                  child: const Text('No'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text(
                    'Yes',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () async {
                    await hitService(phoneNumber, context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

Future<void> hitService(String phoneNumber, context) async {
  try {
    final Uri myUri = Uri.parse(deleteaccount);

    final response = await http.post(
      myUri,
      body: {'user_phone': phoneNumber},
    );

    debugPrint('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData['status'].toString() == "1") {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        if (!context.mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginNavigator()),
              (Route<dynamic> route) => false,
        );
      }
    }
  } catch (e) {
    debugPrint("Delete account error: $e");
  }
}