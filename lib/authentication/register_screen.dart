import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:safir_passengers/appInfo/auth_provider.dart';
import 'package:safir_passengers/authentication/user_information_screen.dart';
import 'package:safir_passengers/methods/common_methods.dart';
import 'package:safir_passengers/pages/blocked_screen.dart';
import 'package:safir_passengers/pages/safir_home_screen.dart';
import 'package:safir_passengers/theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController phoneController =
      TextEditingController();

  final CommonMethods commonMethods = CommonMethods();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (context.locale.languageCode == 'en') {
        context.setLocale(const Locale('fa'));
      }
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  String _getLanguageCodeText(BuildContext context) {
    switch (context.locale.languageCode) {
      case 'ps':
        return 'PS';
      case 'en':
        return 'EN';
      case 'fa':
      default:
        return 'FA';
    }
  }

  void showLanguageBottomSheet(BuildContext context) {
    String bottomSheetTitle;

    if (context.locale.languageCode == 'ps') {
      bottomSheetTitle = 'ژبه غوره کړئ';
    } else if (context.locale.languageCode == 'en') {
      bottomSheetTitle = 'Select Language';
    } else {
      bottomSheetTitle = 'انتخاب زبان';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 10,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                bottomSheetTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _buildLanguageTile(
                context: ctx,
                title: 'دری',
                code: 'fa',
              ),
              const SizedBox(height: 10),
              _buildLanguageTile(
                context: ctx,
                title: 'پښتو',
                code: 'ps',
              ),
              const SizedBox(height: 10),
              _buildLanguageTile(
                context: ctx,
                title: 'English',
                code: 'en',
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageTile({
    required BuildContext context,
    required String title,
    required String code,
  }) {
    final bool isSelected =
        context.locale.languageCode == code;

    return InkWell(
      onTap: () {
        context.setLocale(Locale(code));
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBrand.withOpacity(0.08)
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBrand
                : AppColors.borderLight,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.w600,
                  fontSize: 15,
                  color: isSelected
                      ? AppColors.primaryBrand
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryBrand,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  bool _isPhoneValid(String input) {
    final String clean = input.trim();
    return RegExp(r'^07[0-9]{8}$').hasMatch(clean);
  }

  Future<void> _handleGoogleSignIn(
    AuthenticationProvider authProvider,
  ) async {
    await authProvider.signInWithGoogle(
      context,
      () async {
        final User? currentUser =
            authProvider.firebaseAuth.currentUser;

        if (currentUser == null) {
          if (!mounted) return;

          commonMethods.displaySnackBar(
            'ورود با Google کامل نشد.',
            context,
          );
          return;
        }

        bool userExists;

        try {
          userExists =
              await authProvider.checkUserExistById();
        } on FirebaseException catch (e) {
          if (!mounted) return;

          commonMethods.displaySnackBar(
            'خطا در دریافت اطلاعات کاربر: '
            '${e.message ?? e.code}',
            context,
          );
          return;
        }

        if (!mounted) return;

        if (!userExists) {
          try {
            await authProvider.createInitialPassengerDocument();
          } on FirebaseException catch (e) {
            if (!mounted) return;

            commonMethods.displaySnackBar(
              'ذخیرهٔ اطلاعات کاربر انجام نشد: '
              '${e.message ?? e.code}',
              context,
            );
            return;
          }

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const UserInformationScreen(),
            ),
            (route) => false,
          );
          return;
        }

        final bool isBlocked =
            await authProvider.checkIfUserIsBlocked();

        if (!mounted) return;

        if (isBlocked) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const BlockedScreen(),
            ),
            (route) => false,
          );
          return;
        }

        await authProvider.getUserDataFromFirebaseDatabase();

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const SafirHomeScreen(),
          ),
          (route) => false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthenticationProvider authProvider =
        Provider.of<AuthenticationProvider>(context);

    final bool isValidPhone =
        _isPhoneValid(phoneController.text);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(),
                    GestureDetector(
                      onTap: () =>
                          showLanguageBottomSheet(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2C2C2E)
                              .withOpacity(0.12),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF27B463),
                          ),
                          child: Center(
                            child: Text(
                              _getLanguageCodeText(context),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBrand
                          .withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_android_rounded,
                      color: AppColors.textPrimary,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'welcome_title'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'enter_phone_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _buildSectionHeader(
                  context.locale.languageCode == 'en'
                      ? 'Phone Number'
                      : 'شماره همراه',
                ),
                _buildCardGroup([
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone_android_rounded,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: phoneController,
                            maxLength: 10,
                            textInputAction:
                                TextInputAction.done,
                            keyboardType: TextInputType.phone,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: AppColors.textPrimary,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '0781234567',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 15,
                                letterSpacing: 1.5,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (isValidPhone)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        isValidPhone ? sendPhoneNumber : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isValidPhone
                          ? AppColors.primaryButton
                          : Colors.grey.shade300,
                      disabledBackgroundColor:
                          Colors.grey.shade200,
                      foregroundColor: isValidPhone
                          ? AppColors.buttonText
                          : Colors.grey.shade500,
                      disabledForegroundColor:
                          Colors.grey.shade400,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.buttonText,
                            ),
                          )
                        : Text(
                            getTranslation(
                              context,
                              'get_otp_btn',
                            ),
                            style: TextStyle(
                              color: isValidPhone
                                  ? AppColors.buttonText
                                  : Colors.grey.shade500,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Divider(
                        color: AppColors.borderLight,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      child: Text(
                        getTranslation(
                          context,
                          'or_continue_with',
                        ),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(
                        color: AppColors.borderLight,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed:
                        authProvider.isGoogleSigInLoading
                            ? null
                            : () => _handleGoogleSignIn(
                                  authProvider,
                                ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(
                        color: AppColors.borderLight,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: authProvider.isGoogleSigInLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              color: AppColors.primaryBrand,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.g_mobiledata_rounded,
                                color: Colors.redAccent,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                getTranslation(
                                  context,
                                  'google_sign_in_btn',
                                ),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Text(
                    getTranslation(
                      context,
                      'terms_and_privacy_notice',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      height: 1.5,
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }

  void sendPhoneNumber() {
    final AuthenticationProvider authRepo =
        Provider.of<AuthenticationProvider>(
      context,
      listen: false,
    );

    String rawPhoneNumber =
        phoneController.text.trim();

    if (rawPhoneNumber.startsWith('0')) {
      rawPhoneNumber = rawPhoneNumber.substring(1);
    }

    if (rawPhoneNumber.length != 9 ||
        !RegExp(r'^7[0-9]{8}$')
            .hasMatch(rawPhoneNumber)) {
      commonMethods.displaySnackBar(
        getTranslation(
          context,
          'invalid_phone_warning',
        ),
        context,
      );
      return;
    }

    final String fullPhoneNumber =
        '+93$rawPhoneNumber';

    authRepo.signInWithPhone(
      context: context,
      phoneNumber: fullPhoneNumber,
    );
  }
}
