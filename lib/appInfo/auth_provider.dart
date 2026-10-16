import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:safir_passengers/authentication/otp_screen.dart';
import 'package:safir_passengers/authentication/register_screen.dart';
import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/methods/common_methods.dart';
import 'package:safir_passengers/models/user_model.dart';

class AuthenticationProvider extends ChangeNotifier {
  final CommonMethods commonMethods = CommonMethods();

  bool _isLoading = false;
  bool _isSuccessful = false;
  bool _isGoogleSignedIn = false;
  bool _isGoogleSignInLoading = false;

  String? _uid;
  String? _phoneNumber;
  UserModel? _userModel;

  UserModel? get userModel => _userModel;
  String? get uid => _uid;
  String get phoneNumber => _phoneNumber ?? '';
  bool get isSuccessful => _isSuccessful;
  bool get isLoading => _isLoading;
  bool get isGoogleSignedIn => _isGoogleSignedIn;
  bool get isGoogleSigInLoading =>
      _isGoogleSignInLoading;

  final FirebaseAuth firebaseAuth =
      FirebaseAuth.instance;

  final FirebaseFirestore firebaseFirestore =
      FirebaseFirestore.instance;

  final FirebaseStorage firebaseStorage =
      FirebaseStorage.instance;

  final GoogleSignIn googleSignIn =
      GoogleSignIn();

  CollectionReference<Map<String, dynamic>>
      get _usersCollection =>
          firebaseFirestore.collection('users');

  void startLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void startGoogleLoading() {
    _isGoogleSignInLoading = true;
    notifyListeners();
  }

  void stopGoogleLoading() {
    _isGoogleSignInLoading = false;
    notifyListeners();
  }

  void signInWithPhone({
    required BuildContext context,
    required String phoneNumber,
  }) async {
    startLoading();

    try {
      await firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted:
            (PhoneAuthCredential credential) async {
          try {
            final UserCredential result =
                await firebaseAuth
                    .signInWithCredential(
              credential,
            );

            _uid = result.user?.uid;
            _phoneNumber = phoneNumber;

            stopLoading();
            notifyListeners();
          } on FirebaseAuthException catch (e) {
            stopLoading();

            if (!context.mounted) return;

            commonMethods.displaySnackBar(
              e.message ?? e.toString(),
              context,
            );
          }
        },
        verificationFailed:
            (FirebaseAuthException e) {
          stopLoading();

          if (!context.mounted) return;

          commonMethods.displaySnackBar(
            e.message ?? e.toString(),
            context,
          );
        },
        codeSent: (
          String verificationId,
          int? resendToken,
        ) {
          stopLoading();

          _phoneNumber = phoneNumber;
          notifyListeners();

          Future.delayed(
            const Duration(seconds: 1),
            () {
              if (!context.mounted) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OTPScreen(
                    verificationId: verificationId,
                  ),
                ),
              );
            },
          );
        },
        codeAutoRetrievalTimeout:
            (String verificationId) {
          stopLoading();
        },
      );
    } catch (e) {
      stopLoading();

      if (!context.mounted) return;

      commonMethods.displaySnackBar(
        e.toString(),
        context,
      );
    }
  }

  Future<bool> _checkPhoneNumberExists(
    String phoneNumber,
  ) async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _usersCollection
            .where(
              'phone',
              isEqualTo: phoneNumber.trim(),
            )
            .limit(1)
            .get();

    return snapshot.docs.isNotEmpty;
  }

  void verifyOTP({
    required BuildContext context,
    required String verificationId,
    required String smsCode,
    required Function onSuccess,
  }) async {
    startLoading();

    try {
      final PhoneAuthCredential phoneAuthCredential =
          PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final UserCredential result =
          await firebaseAuth.signInWithCredential(
        phoneAuthCredential,
      );

      final User? user = result.user;

      if (user != null) {
        _uid = user.uid;
        _phoneNumber =
            user.phoneNumber ?? _phoneNumber;
        _isSuccessful = true;

        notifyListeners();
        onSuccess();
      }
    } on FirebaseException catch (e) {
      if (!context.mounted) return;

      commonMethods.displaySnackBar(
        e.message ?? e.toString(),
        context,
      );
    } finally {
      stopLoading();
    }
  }

  Future<void> saveUserDataToFirebase({
    required BuildContext context,
    required UserModel userModel,
    required VoidCallback onSuccess,
  }) async {
    startLoading();

    try {
      final User? currentUser =
          firebaseAuth.currentUser;

      if (currentUser == null) {
        throw FirebaseAuthException(
          code: 'user-not-signed-in',
          message: 'ابتدا وارد حساب کاربری شوید.',
        );
      }

      final String userId = currentUser.uid;

      final Map<String, dynamic> userData = {
        ...userModel.toMap(),
        'id': userId,
        'email': userModel.email.isNotEmpty
            ? userModel.email
            : (currentUser.email ?? ''),
        'phone': userModel.phone.isNotEmpty
            ? userModel.phone
            : (currentUser.phoneNumber ??
                _phoneNumber ??
                ''),
        'role': 'passenger',
        'blockStatus': 'no',
        'isBlocked': false,
        'isApproved': true,
        'status': 'active',
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      };

      await _usersCollection.doc(userId).set(
            userData,
            SetOptions(merge: true),
          );

      _uid = userId;

      _userModel = UserModel(
        id: userId,
        name: userData['name']?.toString() ?? '',
        email:
            userData['email']?.toString() ?? '',
        phone:
            userData['phone']?.toString() ?? '',
        blockStatus:
            userData['blockStatus']?.toString() ??
                'no',
      );

      notifyListeners();
      onSuccess();
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      commonMethods.displaySnackBar(
        e.message ?? e.toString(),
        context,
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;

      commonMethods.displaySnackBar(
        e.message ?? e.toString(),
        context,
      );
    } catch (e) {
      if (!context.mounted) return;

      commonMethods.displaySnackBar(
        e.toString(),
        context,
      );
    } finally {
      stopLoading();
    }
  }

  Future<bool> checkUserExistByEmail(
    String email,
  ) async {
    final String cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      return false;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot = await _usersCollection
              .where(
                'email',
                isEqualTo: cleanEmail,
              )
              .limit(1)
              .get();

      return snapshot.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      debugPrint(
        'Error checking user by email: '
        '${e.code} - ${e.message}',
      );

      return false;
    } catch (e) {
      debugPrint(
        'Error checking user by email: $e',
      );

      return false;
    }
  }

  Future<bool> checkUserExistByPhone(
    String phoneNumber,
  ) async {
    final String cleanPhone =
        phoneNumber.trim();

    if (cleanPhone.isEmpty) {
      return false;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot = await _usersCollection
              .where(
                'phone',
                isEqualTo: cleanPhone,
              )
              .limit(1)
              .get();

      return snapshot.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      debugPrint(
        'Error checking user by phone: '
        '${e.code} - ${e.message}',
      );

      return false;
    } catch (e) {
      debugPrint(
        'Error checking user by phone: $e',
      );

      return false;
    }
  }

  Future<bool> checkUserExistById() async {
    final User? currentUser =
        firebaseAuth.currentUser;

    if (currentUser == null) {
      return false;
    }

    try {
      final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot = await _usersCollection
              .doc(currentUser.uid)
              .get();

      return snapshot.exists;
    } on FirebaseException catch (e) {
      debugPrint(
        'Error checking user by id: '
        '${e.code} - ${e.message}',
      );

      return false;
    } catch (e) {
      debugPrint(
        'Error checking user by id: $e',
      );

      return false;
    }
  }

  Future<void>
      getUserDataFromFirebaseDatabase() async {
    try {
      final User? currentUser =
          firebaseAuth.currentUser;

      if (currentUser == null) {
        return;
      }

      final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot = await _usersCollection
              .doc(currentUser.uid)
              .get();

      if (!snapshot.exists ||
          snapshot.data() == null) {
        debugPrint(
          'User data not found in Firestore.',
        );
        return;
      }

      final Map<String, dynamic> userData =
          snapshot.data()!;

      _userModel = UserModel(
        id: userData['id']?.toString() ??
            currentUser.uid,
        name: userData['name']?.toString() ?? '',
        email:
            userData['email']?.toString() ?? '',
        phone:
            userData['phone']?.toString() ?? '',
        blockStatus:
            userData['blockStatus']?.toString() ??
                'no',
      );

      _uid = _userModel!.id;

      notifyListeners();
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore error while fetching user: '
        '${e.code} - ${e.message}',
      );
    } catch (e) {
      debugPrint(
        'Error while fetching user data: $e',
      );
    }
  }

  Future<bool> checkIfUserIsBlocked() async {
    try {
      final User? currentUser =
          firebaseAuth.currentUser;

      if (currentUser == null) {
        return false;
      }

      final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot = await _usersCollection
              .doc(currentUser.uid)
              .get();

      // نبودن سند به‌معنای مسدود بودن نیست.
      if (!snapshot.exists ||
          snapshot.data() == null) {
        return false;
      }

      final Map<String, dynamic> userData =
          snapshot.data()!;

      final dynamic rawBlockStatus =
          userData['blockStatus'];

      final String blockStatus =
          rawBlockStatus
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      final bool isBlockedFromAdmin =
          userData['isBlocked'] == true;

      final bool isBlocked =
          blockStatus == 'yes' ||
          blockStatus == 'blocked' ||
          blockStatus == 'true' ||
          isBlockedFromAdmin;

      if (!isBlocked) {
        return false;
      }

      // فقط کاربر مسدود واقعی از Firebase خارج می‌شود.
      await firebaseAuth.signOut();

      try {
        await googleSignIn.signOut();
      } catch (e) {
        debugPrint(
          'Google sign out after block failed: $e',
        );
      }

      _uid = null;
      _phoneNumber = null;
      _userModel = null;
      _isGoogleSignedIn = false;
      _isSuccessful = false;

      notifyListeners();

      return true;
    } on FirebaseException catch (e) {
      // خطای Firestore نباید باعث Logout شود.
      debugPrint(
        'Firestore error while checking block status: '
        '${e.code} - ${e.message}',
      );

      return false;
    } catch (e) {
      // خطای عادی هم نباید باعث Logout شود.
      debugPrint(
        'Error while checking user block status: $e',
      );

      return false;
    }
  }

  Future<bool> checkUserFieldsFilled() async {
    try {
      final User? currentUser =
          firebaseAuth.currentUser;

      if (currentUser == null) {
        return false;
      }

      final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot = await _usersCollection
              .doc(currentUser.uid)
              .get();

      if (!snapshot.exists ||
          snapshot.data() == null) {
        return false;
      }

      final Map<String, dynamic> userData =
          snapshot.data()!;

      final String id =
          userData['id']?.toString() ?? '';

      final String name =
          userData['name']?.toString() ?? '';

      final String email =
          userData['email']?.toString() ?? '';

      final String phone =
          userData['phone']?.toString() ?? '';

      return id.isNotEmpty &&
          name.isNotEmpty &&
          email.isNotEmpty &&
          phone.isNotEmpty;
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore error while checking fields: '
        '${e.code} - ${e.message}',
      );

      return false;
    } catch (e) {
      debugPrint(
        'Error while checking user fields: $e',
      );

      return false;
    }
  }

  Future<void> signInWithGoogle(
    BuildContext context,
    VoidCallback onSuccess,
  ) async {
    startGoogleLoading();

    try {
      final GoogleSignInAccount? googleUser =
          await googleSignIn.signIn();

      // کاربر پنجره Google را بسته است.
      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication
          googleAuth = await googleUser.authentication;

      final String? accessToken =
          googleAuth.accessToken;

      final String? idToken =
          googleAuth.idToken;

      if (accessToken == null && idToken == null) {
        throw FirebaseAuthException(
          code: 'google-auth-token-null',
          message:
              'Google authentication token is empty.',
        );
      }

      final AuthCredential credential =
          GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final UserCredential userCredential =
          await firebaseAuth.signInWithCredential(
        credential,
      );

      final User? user =
          userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'google-user-null',
          message:
              'Google user is null after sign in.',
        );
      }

      // تازه‌سازی کاربر Firebase.
      await user.reload();

      final User? signedInUser =
          firebaseAuth.currentUser;

      if (signedInUser == null) {
        throw FirebaseAuthException(
          code: 'firebase-user-null-after-login',
          message:
              'Firebase user is null after Google sign in.',
        );
      }

      _uid = signedInUser.uid;
      _phoneNumber = signedInUser.phoneNumber;
      _isGoogleSignedIn = true;
      _isSuccessful = true;

      notifyListeners();

      onSuccess();
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      commonMethods.displaySnackBar(
        e.message ??
            getTranslation(
              context,
              'google_sign_in_error',
            ),
        context,
      );
    } catch (e) {
      if (!context.mounted) return;

      commonMethods.displaySnackBar(
        e.toString(),
        context,
      );
    } finally {
      stopGoogleLoading();
    }
  }

  Future<void> signOut(
    BuildContext context,
  ) async {
    startLoading();

    try {
      await firebaseAuth.signOut();
      await googleSignIn.signOut();

      _uid = null;
      _phoneNumber = null;
      _userModel = null;
      _isGoogleSignedIn = false;
      _isSuccessful = false;

      notifyListeners();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const RegisterScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      commonMethods.displaySnackBar(
        e.message ??
            getTranslation(
              context,
              'sign_out_error',
            ),
        context,
      );
    } finally {
      stopLoading();
    }
  }
}
