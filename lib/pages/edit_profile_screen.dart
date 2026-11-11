import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/theme/app_colors.dart';
import 'package:safir_passengers/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 🔹 دریافت مستقیم اطلاعات کاربر از فایربیس و فایرستور
  Future<void> _loadUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // ۱. دریافت اطلاعات پایه از اکانت فعال فایربیس
      if (currentUser.phoneNumber != null && currentUser.phoneNumber!.isNotEmpty) {
        userPhone = currentUser.phoneNumber!;
      }
      if (currentUser.email != null && currentUser.email!.isNotEmpty) {
        userEmail = currentUser.email!;
      }
      if (currentUser.displayName != null && currentUser.displayName!.isNotEmpty) {
        userName = currentUser.displayName!;
      }

      try {
        // ۲. تکمیل اطلاعات از دیتابیس Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          userName = data["name"] ?? data["fullName"] ?? userName;
          userPhone = data["phone"] ?? data["phoneNumber"] ?? userPhone;
          userEmail = data["email"] ?? userEmail;
        }
      } catch (e) {
        debugPrint("Error fetching profile: $e");
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// یک ردیف اطلاعات با آیکن رنگی داخل کادر نرم
  Widget _infoRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        surfaceTintColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          "my_profile_title".tr(),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryBrand),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              child: Column(
                children: [
                  // بخش آواتار و نام
                  Center(
                    child: Container(
                      width: 112,
                      height: 112,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryBrand.withOpacity(0.35),
                          width: 2,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.cardBackground,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 62,
                          color: AppColors.primaryBrand,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    userName.isEmpty ? "unknown_text".tr() : userName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // کارت نمایش اطلاعات کاربری
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBgLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: Column(
                      children: [
                        _infoRow(
                          icon: Icons.person_rounded,
                          color: AppColors.primaryBrand,
                          label: "full_name_label".tr(),
                          value:
                              userName.isEmpty ? "unknown_text".tr() : userName,
                        ),
                        Divider(
                          height: 1,
                          indent: 70,
                          endIndent: 14,
                          color: AppColors.fieldBorder,
                        ),
                        _infoRow(
                          icon: Icons.phone_rounded,
                          color: AppColors.successDark,
                          label: "phone_number_label".tr(),
                          value: userPhone.isEmpty
                              ? "unknown_text".tr()
                              : formatNumberByLocale(context, userPhone),
                        ),
                        Divider(
                          height: 1,
                          indent: 70,
                          endIndent: 14,
                          color: AppColors.fieldBorder,
                        ),
                        _infoRow(
                          icon: Icons.mail_rounded,
                          color: AppColors.originBlue,
                          label: "email_address_label".tr(),
                          value:
                              userEmail.isEmpty ? "unknown_text".tr() : userEmail,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // دکمه هدایت به صفحه ویرایش اطلاعات
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryButton,
                        overlayColor: AppColors.primaryButtonPressed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (c) => const EditProfileScreen()),
                        ).then((_) {
                          _loadUserData(); // به‌روزرسانی مجدد پس از بازگشت از صفحه ویرایش
                        });
                      },
                      icon: Icon(
                        Icons.edit_rounded,
                        color: AppColors.buttonText,
                        size: 20,
                      ),
                      label: Text(
                        "edit_profile_btn".tr(),
                        style: TextStyle(
                          color: AppColors.buttonText,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
