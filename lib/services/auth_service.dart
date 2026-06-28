import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/snackbar_helper.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> createUserProfile(
      String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data);
  }

  Future<void> sendEmailVerification(User user) async {
    await user.sendEmailVerification();
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut(); // also clear Google session
    await _auth.signOut();
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // user cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      // Guard context after async gap
      if (!context.mounted) return;

      if (user == null) {
        SnackBarHelper.showError(context, 'Google Sign-In failed. Try again.');
        return;
      }

      final docSnap = await _db.collection('users').doc(user.uid).get();

      // Guard context after second async gap
      if (!context.mounted) return;

      final data = docSnap.data();
      final bool isReturning = docSnap.exists &&
          (data?['phoneNumber'] as String? ?? '').isNotEmpty &&
          (data?['city'] as String? ?? '').isNotEmpty;

      if (isReturning) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/main', (route) => false);
      } else {
        await _db.collection('users').doc(user.uid).set(
          {
            'uid': user.uid,
            'email': user.email ?? '',
            'name': user.displayName ?? '',
            'photoUrl': user.photoURL ?? '',
          },
          SetOptions(merge: true),
        );

        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(
            context, '/profile-completion', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(
            context, e.message ?? 'Google Sign-In failed.');
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(
            context, 'Google Sign-In failed. Please try again.');
      }
    }
  }
}
