import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:safir_passengers/authentication/otp_screen.dart';
import 'package:safir_passengers/authentication/register_screen.dart';
import 'package:safir_passengers/global/global_var.dart';
import 'package:safir_passengers/methods/common_methods.dart';
import 'package:safir_passengers/models/user_model.dart';

class AuthenticationProvider extends ChangeNotifier {
  AuthenticationProvider();

  final CommonMethods commonMethods = CommonMethods();

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore =
      FirebaseFirestore.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

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
  bool get isGoogleSigInLoading => _isGoogleSignInLoading;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
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

  void _setCurrentUser(User user) {
    _uid = user.uid;
    _phoneNumber = user.phoneNumber;

    _isGoogleSignedIn = user.providerData.any(
      (provider) => provider.providerId == 'google.com',
    );
  }

  Future<void> signInWithPhone({
    required BuildContext context,
    required String phoneNumber,
  }) async {
    startLoading();

    try {
      await firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final UserCredential result =
                await firebaseAuth.signInWithCredential(credential);

            final User? user = result.user;

            if (user != null) {
              _uid = user.uid;
              _phoneNumber = user.phoneNumber ?? phoneNumber;
              _isSuccessful = true;
              notifyListeners();
            }
          } on FirebaseAuthException catch (e) {
            if (!context.mounted) return;

            commonMethods.displaySnackBar(
              e.message ?? e.toString(),
              context,
            );
          } finally {
            stopLoading();
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          stopLoading();

          if (!context.mounted) return;

          commonMethods.displaySnackBar(
            e.message ?? e.toString(),
            context,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          stopLoading();

          _phoneNumber = phoneNumber;
          notifyListeners();

          Future.delayed(const Duration(seconds: 1), () {
            if (!context.mounted) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OTPScreen(
                  verificationId: verificationId,
                ),
              ),
            );
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
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

  Future<void> verifyOTP({
    required BuildContext context,
    required String verificationId,
    required String smsCode,
    required Future<void> Function() onSuccess,
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

      if (user == null) {
        throw FirebaseAuthException(
          code: 'phone-user-null',
          message: 'کاربر تلفنی دریافت نشد.',
        );
      }

      _uid = user.uid;
      _phoneNumber = user.phoneNumber ?? _phoneNumber;
      _isSuccessful = true;

      notifyListeners();

      await onSuccess();
    } on FirebaseAuthException catch (e) {
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
      final User? currentUser = firebaseAuth.currentUser;

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
        'email': userModel.email.trim().isNotEmpty
            ? userModel.email.trim()
            : currentUser.email ?? '',
        'phone': userModel.phone.trim().isNotEmpty
            ? userModel.phone.trim()
            : currentUser.phoneNumber ?? _phoneNumber ?? '',
        'role': 'passenger',
        'blockStatus': 'no',
        'isBlocked': false,
        'isApproved': true,
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _usersCollection.doc(userId).set(
        {
          ...userData,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _uid = userId;

      _userModel = UserModel(
        id: userId,
        name: userData['name']?.toString() ?? '',
        email: userData['email']?.toString() ?? '',
        phone: userData['phone']?.toString() ?? '',
        blockStatus: userData['blockStatus']?.toString() ?? 'no',
      );

      notifyListeners();

      onSuccess();
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'saveUserDataToFirebase Auth error: '
        '${e.code} - ${e.message}',
      );

      if (!context.mounted) return;

      commonMethods.displaySnackBar(
        e.message ?? e.toString(),
        context,
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'saveUserDataToFirebase Firebase error: '
        '${e.code} - ${e.message}',
      );

      if (!context.mounted) return;

      commonMethods.displaySnackBar(
        e.message ?? e.toString(),
        context,
      );
    } catch (e) {
      debugPrint('saveUserDataToFirebase error: $e');

      if (!context.mounted) return;

      commonMethods.displaySnackBar(
        e.toString(),
        context,
      );
    } finally {
      stopLoading();
    }
  }

  Future<bool> checkUserExistById() async {
    final User? currentUser = firebaseAuth.currentUser;

    if (currentUser == null) {
      return false;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _usersCollection.doc(currentUser.uid).get();

    return snapshot.exists;
  }

  Future<void> createInitialPassengerDocument() async {
    final User? currentUser = firebaseAuth.currentUser;

    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-signed-in',
        message: 'کاربر وارد نشده است.',
      );
    }

    final DocumentReference<Map<String, dynamic>> userRef =
        _usersCollection.doc(currentUser.uid);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await userRef.get();

    if (snapshot.exists) {
      return;
    }

    await userRef.set({
      'id': currentUser.uid,
      'name': currentUser.displayName ?? '',
      'email': currentUser.email ?? '',
      'phone': currentUser.phoneNumber ?? '',
      'role': 'passenger',
      'blockStatus': 'no',
      'isBlocked': false,
      'isApproved': true,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _uid = currentUser.uid;

    _userModel = UserModel(
      id: currentUser.uid,
      name: currentUser.displayName ?? '',
      email: currentUser.email ?? '',
      phone: currentUser.phoneNumber ?? '',
      blockStatus: 'no',
    );

    notifyListeners();
  }

  Future<void> getUserDataFromFirebaseDatabase() async {
    final User? currentUser = firebaseAuth.currentUser;

    if (currentUser == null) return;

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _usersCollection.doc(currentUser.uid).get();

      if (!snapshot.exists || snapshot.data() == null) {
        debugPrint(
          'User document not found: users/${currentUser.uid}',
        );
        return;
      }

      final Map<String, dynamic> userData = snapshot.data()!;

      _userModel = UserModel(
        id: userData['id']?.toString() ?? currentUser.uid,
        name: userData['name']?.toString() ?? '',
        email: userData['email']?.toString() ??
            currentUser.email ??
            '',
        phone: userData['phone']?.toString() ??
            currentUser.phoneNumber ??
            '',
        blockStatus: userData['blockStatus']?.toString() ?? 'no',
      );

      _uid = _userModel!.id;

      notifyListeners();
    } on FirebaseException catch (e) {
      debugPrint(
        'getUserDataFromFirebaseDatabase error: '
        '${e.code} - ${e.message}',
      );
    } catch (e) {
      debugPrint(
        'getUserDataFromFirebaseDatabase unknown error: $e',
      );
    }
  }

  Future<bool> checkIfUserIsBlocked() async {
    final User? currentUser = firebaseAuth.currentUser;

    if (currentUser == null) {
      return false;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _usersCollection.doc(currentUser.uid).get();

      if (!snapshot.exists || snapshot.data() == null) {
        return false;
      }

      final Map<String, dynamic> userData = snapshot.data()!;

      final String blockStatus =
          userData['blockStatus']?.toString().toLowerCase() ?? 'no';

      final bool isBlockedByBoolean =
          userData['isBlocked'] == true;

      final bool isBlocked =
          blockStatus == 'yes' ||
          blockStatus == 'blocked' ||
          isBlockedByBoolean;

      if (!isBlocked) {
        return false;
      }

      await firebaseAuth.signOut();
      await googleSignIn.signOut();

      _uid = null;
      _phoneNumber = null;
      _userModel = null;
      _isGoogleSignedIn = false;
      _isSuccessful = false;

      notifyListeners();

      return true;
    } on FirebaseException catch (e) {
      debugPrint(
        'checkIfUserIsBlocked error: '
        '${e.code} - ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint(
        'checkIfUserIsBlocked unknown error: $e',
      );
      return false;
    }
  }

  Future<bool> checkUserFieldsFilled() async {
    final User? currentUser = firebaseAuth.currentUser;

    if (currentUser == null) {
      return false;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _usersCollection.doc(currentUser.uid).get();

      if (!snapshot.exists || snapshot.data() == null) {
        return false;
      }

      final Map<String, dynamic> userData = snapshot.data()!;

      final String id = userData['id']?.toString() ?? '';
      final String name = userData['name']?.toString() ?? '';
      final String email = userData['email']?.toString() ?? '';
      final String phone = userData['phone']?.toString() ?? '';

      return id.isNotEmpty &&
          name.isNotEmpty &&
          email.isNotEmpty &&
          phone.isNotEmpty;
    } on FirebaseException catch (e) {
      debugPrint(
        'checkUserFieldsFilled error: '
        '${e.code} - ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint(
        'checkUserFieldsFilled unknown error: $e',
      );
      return false;
    }
  }

  Future<void> signInWithGoogle(
    BuildContext context,
    Future<void> Function() onSuccess,
  ) async {
    startGoogleLoading();

    try {
      final GoogleSignInAccount? googleUser =
          await googleSignIn.signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential =
          GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await firebaseAuth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'google-user-null',
          message: 'کاربر Google دریافت نشد.',
        );
      }

      _setCurrentUser(user);
      _isSuccessful = true;

      notifyListeners();

      await onSuccess();
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Google FirebaseAuth error: '
        '${e.code} - ${e.message}',
      );

      if (!context.mounted) return;

      commonMethods.displaySnackBar(
        e.message ?? getTranslation(
          context,
          'google_sign_in_error',
        ),
        context,
      );
    } catch (e) {
      debugPrint('Google sign-in error: $e');

      if (!context.mounted) return;

      commonMethods.displaySnackBar(
        e.toString(),
        context,
      );
    } finally {
      stopGoogleLoading();
    }
  }

  Future<void> signOut(BuildContext context) async {
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
          builder: (_) => const RegisterScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      commonMethods.displaySnackBar(
        e.message ?? getTranslation(
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
