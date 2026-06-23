// baseurl.dart me ye dono URL add kar lena:
//
// String signupOtp = "${baseUrl}signup-otp";
// String signupVerify = "${baseUrl}signup-verify";
//
// NOTE: userSignup pehle se aapke code me hai.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../Themes/colors.dart';
import '../../baseurlp/baseurl.dart';

class KpkbRegisterScreen extends StatefulWidget {
  const KpkbRegisterScreen({super.key});

  @override
  State<KpkbRegisterScreen> createState() => _KpkbRegisterScreenState();
}

class _KpkbRegisterScreenState extends State<KpkbRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final regCtrl = TextEditingController();
  final cardCtrl = TextEditingController();

  final Color bgColor = Colors.white;
  final Color primary = black_color;
  final Color lightBlue = const Color(0xffEEF6FF);

  File? idCardImage;
  bool imageError = false;
  bool isSubmitting = false;
  bool isOtpSending = false;
  bool isOtpVerifying = false;
  bool otpSent = false;
  bool isMobileVerified = false;

  String? imageErrorText;
  String? selectedForce;
  String? selectedRank;

  int? otpUserId;

  final int minImageSize = 300 * 1024;
  final int maxImageSize = 350 * 1024;

  final List<String> forcesList = [
    "Serving ITBPF",
    "Ex-Servicemen ITBPF",
  ];

  final List<String> rankList = [
    "GOs",
    "SOs",
    "ORs",
  ];

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      final file = File(picked.path);
      final size = await file.length();

      if (size > maxImageSize) {
        setState(() {
          idCardImage = null;
          imageError = true;
          imageErrorText = "Image size must be 300 KB to 350 KB only";
        });
        return;
      }

      setState(() {
        idCardImage = file;
        imageError = false;
        imageErrorText = null;
      });
    }
  }

  Future<void> sendOtp() async {
    FocusScope.of(context).unfocus();

    final mobile = mobileCtrl.text.trim();

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(mobile)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter valid mobile number"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      setState(() => isOtpSending = true);

      final response = await http.post(
        Uri.parse(userSignupOtp),
        body: {
          "mobile": mobile,
        },
      );

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      if (!mounted) return;

      setState(() => isOtpSending = false);

      if (response.statusCode == 200 && data["status"].toString() == "1") {
        setState(() {
          otpSent = true;
          isMobileVerified = false;
          otpUserId = int.tryParse(data["user"].toString());
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"]?.toString() ?? "OTP sent successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          otpSent = false;
          isMobileVerified = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"]?.toString() ?? "OTP send failed"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => isOtpSending = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("OTP error: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> verifyOtp() async {
    FocusScope.of(context).unfocus();

    final mobile = mobileCtrl.text.trim();
    final otp = otpCtrl.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter OTP"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      setState(() => isOtpVerifying = true);

      final response = await http.post(
        Uri.parse(userSignupOtpVerify),
        body: {
          "mobile": mobile,
          "otp": otp,
        },
      );

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      if (!mounted) return;

      setState(() => isOtpVerifying = false);

      if (response.statusCode == 200 && data["status"].toString() == "1") {
        setState(() {
          isMobileVerified = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"]?.toString() ?? "Mobile verified"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => isMobileVerified = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"]?.toString() ?? "Invalid OTP"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => isOtpVerifying = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Verify OTP error: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();

    if (!isMobileVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please verify mobile number first"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      imageError = idCardImage == null;
      imageErrorText = idCardImage == null
          ? "Image is required. Upload 300 KB to 350 KB image"
          : null;
    });

    final isFormValid = _formKey.currentState!.validate();

    if (!isFormValid || idCardImage == null) return;

    final int rankValue = selectedRank == "GOs"
        ? 1
        : selectedRank == "SOs"
        ? 2
        : 3;

    final int retiredValue = selectedForce == "Ex-Servicemen ITBPF" ? 1 : 0;

    try {
      setState(() => isSubmitting = true);

      final uri = Uri.parse(userSignup);

      final request = http.MultipartRequest("POST", uri);

      final Map<String, String> fields = {
        "name": nameCtrl.text.trim(),
        "mobile": mobileCtrl.text.trim(),
        "regimental_no": regCtrl.text.trim(),
        "rank": rankValue.toString(),
        "retired": retiredValue.toString(),
        "card_no": cardCtrl.text.trim(),
      };

      request.fields.addAll(fields);

      print('data$fields}');

      request.files.add(
        await http.MultipartFile.fromPath(
          "card",
          idCardImage!.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      if (!mounted) return;

      setState(() => isSubmitting = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"]?.toString() ?? "Register Success"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"]?.toString() ?? "Registration failed"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Something went wrong: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    mobileCtrl.dispose();
    otpCtrl.dispose();
    regCtrl.dispose();
    cardCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = isSubmitting || isOtpSending || isOtpVerifying;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
        ),
        title: const Text(
          "Registration",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 25),

                buildField(
                  title: "Name as per PAN card",
                  hint: "Enter your name",
                  icon: Icons.person_outline_rounded,
                  controller: nameCtrl,
                ),

                buildField2(
                  title: "Mobile Number",
                  hint: "Enter mobile number",
                  icon: Icons.phone_outlined,
                  controller: mobileCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onChanged: (_) {
                    if (isMobileVerified || otpSent) {
                      setState(() {
                        isMobileVerified = false;
                        otpSent = false;
                        otpCtrl.clear();
                        otpUserId = null;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Mobile number required";
                    }
                    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) {
                      return "Enter valid 10 digit number";
                    }
                    return null;
                  },
                ),

                _otpSection(),

                buildField2(
                  title: "Regimental/PPO No.",
                  hint: "Enter Regimental/PPO Number",
                  icon: Icons.assignment_outlined,
                  controller: regCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(20),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Regimental/PPO number required";
                    }
                    if (value.trim().length != 20) {
                      return "Regimental number must be 20 digits";
                    }
                    return null;
                  },
                ),

                buildDropdownField(
                  title: "Rank",
                  icon: Icons.military_tech_outlined,
                  value: selectedRank,
                  items: rankList,
                  onChanged: (value) {
                    setState(() => selectedRank = value);
                  },
                ),

                buildDropdownField(
                  title: "Employee",
                  icon: Icons.shield_outlined,
                  value: selectedForce,
                  items: forcesList,
                  onChanged: (value) {
                    setState(() => selectedForce = value);
                  },
                ),

                buildField2(
                  title: "KPKB Assist Id Card No.",
                  hint: "ITBAB12CD3456",
                  icon: Icons.badge_outlined,
                  controller: cardCtrl,
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    ITBTextFormatter(),
                  ],
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty ||
                        value.trim() == "ITB") {
                      return "ID Card No. required";
                    }

                    if (!RegExp(r'^ITB[A-Z0-9]{10}$').hasMatch(value.trim())) {
                      return "Enter valid ID";
                    }

                    return null;
                  },
                ),

                _uploadCard(),

                const SizedBox(height: 20),

                SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMobileVerified
                          ? kButtonColor
                          : Colors.grey.shade500,
                      disabledBackgroundColor: Colors.grey.shade500,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed:
                    isSubmitting || !isMobileVerified ? null : _submitForm,
                    child: isSubmitting
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      isMobileVerified
                          ? "SUBMIT"
                          : "VERIFY MOBILE FIRST",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: .8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _otpSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSubmitting || isOtpSending || isMobileVerified
                  ? null
                  : sendOtp,
              icon: isMobileVerified
                  ? const Icon(Icons.verified_rounded, color: Colors.white)
                  : const Icon(Icons.sms_outlined, color: Colors.white),
              label: isOtpSending
                  ?  SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kButtonColor,
                ),
              )
                  : Text(
                isMobileVerified ? "MOBILE VERIFIED" : "SEND OTP",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                isMobileVerified ? Colors.green : kButtonColor,
                disabledBackgroundColor:
                isMobileVerified ? Colors.green : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          if (otpSent && !isMobileVerified) ...[
            const SizedBox(height: 12),
            buildField2(
              title: "OTP",
              hint: "Enter OTP",
              icon: Icons.lock_outline_rounded,
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: null,
            ),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting || isOtpVerifying ? null : verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.green.withOpacity(.55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isOtpVerifying
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  "VERIFY OTP",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildField({
    required String title,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: _fieldDecoration(),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: !isSubmitting,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return "$title required";
          }
          return null;
        },
        decoration: _inputDecoration(title, hint, icon),
      ),
    );
  }

  Widget buildField2({
    required String title,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    final bool isMobileField = title.toLowerCase().contains("mobile");
    final bool isIdField = title.toLowerCase().contains("id card");

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        onChanged: onChanged,
        enabled: !isSubmitting,
        textCapitalization: TextCapitalization.characters,
        onTap: () {
          if (isIdField && controller.text.isEmpty) {
            controller.text = "ITB";
            controller.selection = TextSelection.collapsed(
              offset: controller.text.length,
            );
          }
        },
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 17,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.black,
                  size: 22,
                ),
                if (isMobileField) ...[
                  const SizedBox(width: 6),
                  const Text(
                    "+91",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          hintText: isIdField ? "ITBAB12CD3456" : hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget buildDropdownField({
    required String title,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: _fieldDecoration(),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(18),
        menuMaxHeight: 260,
        elevation: 8,
        icon: Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            color: primary.withOpacity(.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primary,
            size: 24,
          ),
        ),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
        decoration: _inputDecoration(title, "Select $title", icon),
        selectedItemBuilder: (context) {
          return items.map((e) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                e,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          }).toList();
        },
        items: items.map((e) {
          final bool isSelected = value == e;

          return DropdownMenuItem<String>(
            value: e,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? primary.withOpacity(.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primary.withOpacity(.14)
                          : Colors.grey.withOpacity(.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: isSelected ? primary : Colors.black45,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e,
                      style: TextStyle(
                        color: isSelected ? primary : Colors.black87,
                        fontSize: 14,
                        fontWeight:
                        isSelected ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        onChanged: isSubmitting ? null : onChanged,
        validator: (v) {
          if (v == null || v.isEmpty) {
            return "Select $title";
          }
          return null;
        },
      ),
    );
  }

  Widget _uploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: imageError ? Colors.red : Colors.grey.shade200,
          width: imageError ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                color: imageError ? Colors.red : primary,
              ),
              const SizedBox(width: 8),
              Text(
                "Upload KPKB Card Image",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: imageError ? Colors.red : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            "You can upload image between 300 KB to 350 KB only",
            style: TextStyle(
              color: imageError ? Colors.red : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: isSubmitting ? null : pickImage,
            child: Container(
              height: 135,
              width: double.infinity,
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: imageError ? Colors.red : primary.withOpacity(.25),
                  width: imageError ? 1.5 : 1,
                ),
              ),
              child: idCardImage == null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 36,
                    color: imageError ? Colors.red : primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap to choose image",
                    style: TextStyle(
                      color: imageError ? Colors.red : primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    imageErrorText ?? "JPG / PNG supported",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: imageError ? Colors.red : Colors.black45,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.file(
                  idCardImage!,
                  width: double.infinity,
                  height: 135,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.black),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.035),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
      String title,
      String hint,
      IconData icon, {
        String? prefixText,
      }) {
    return InputDecoration(
      prefixIcon: Icon(
        icon,
        color: primary,
        size: 22,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      prefixText: prefixText,
      prefixStyle: TextStyle(
        color: primary,
        fontWeight: FontWeight.w900,
        fontSize: 14,
      ),
      labelText: title,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      labelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      hintStyle: const TextStyle(
        color: Colors.black,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: primary.withOpacity(.55),
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.4,
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class ITBTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String text = newValue.text.toUpperCase();

    text = text.replaceAll(RegExp(r'[^A-Z0-9]'), '');

    if (text.startsWith("ITB")) {
      text = text.substring(3);
    }

    if (text.length > 15) {
      text = text.substring(0, 15);
    }

    final finalText = "ITB$text";

    return TextEditingValue(
      text: finalText,
      selection: TextSelection.collapsed(offset: finalText.length),
    );
  }
}