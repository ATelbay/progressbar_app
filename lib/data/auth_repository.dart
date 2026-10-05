import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum AuthFailureKind {
  invalidPhone,
  invalidCode,
  codeExpired,
  tooManyRequests,
  network,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.kind, [this.details]);

  final AuthFailureKind kind;
  final String? details;

  @override
  String toString() => 'AuthFailure(${kind.name}, $details)';
}

/// Phone sign-in: send a code, confirm it, sign out.
abstract interface class AuthRepository {
  /// The signed-in user's id, or null when signed out.
  Stream<String?> get uid;

  String? get phoneNumber;

  /// Sends the SMS code to [phone] in E.164 form. Completes once the code is
  /// on its way, or once the device verified the number by itself.
  Future<void> sendCode(String phone);

  Future<void> confirmCode(String smsCode);

  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth)
    // Lets fictional test numbers from the Firebase console sign in on
    // simulators, where the app cannot be verified.
    : _ready = kDebugMode
          ? _auth.setSettings(appVerificationDisabledForTesting: true)
          : Future.value();

  final Future<void> _ready;
  final FirebaseAuth _auth;
  String? _verificationId;
  int? _resendToken;

  @override
  Stream<String?> get uid => _auth.authStateChanges().map((user) => user?.uid);

  @override
  String? get phoneNumber => _auth.currentUser?.phoneNumber;

  @override
  Future<void> sendCode(String phone) async {
    await _ready;
    final sent = Completer<void>();
    void finish([Object? error]) {
      if (sent.isCompleted) return;
      error == null ? sent.complete() : sent.completeError(error);
    }

    _auth
        .verifyPhoneNumber(
          phoneNumber: phone,
          forceResendingToken: _resendToken,
          verificationCompleted: (credential) async {
            try {
              await _auth.signInWithCredential(credential);
              finish();
            } on FirebaseAuthException catch (e) {
              finish(_failure(e));
            }
          },
          verificationFailed: (e) => finish(_failure(e)),
          codeSent: (verificationId, resendToken) {
            _verificationId = verificationId;
            _resendToken = resendToken;
            finish();
          },
          codeAutoRetrievalTimeout: (verificationId) =>
              _verificationId = verificationId,
        )
        .catchError((Object e) {
          finish(
            e is FirebaseAuthException
                ? _failure(e)
                : AuthFailure(AuthFailureKind.unknown, '$e'),
          );
        });
    return sent.future;
  }

  @override
  Future<void> confirmCode(String smsCode) async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      throw const AuthFailure(AuthFailureKind.codeExpired);
    }
    try {
      await _auth.signInWithCredential(
        PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        ),
      );
    } on FirebaseAuthException catch (e) {
      throw _failure(e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AuthFailure _failure(FirebaseAuthException e) {
    debugPrint('Phone sign-in failed: $e');
    return AuthFailure(switch (e.code) {
      'invalid-phone-number' ||
      'missing-phone-number' => AuthFailureKind.invalidPhone,
      'invalid-verification-code' ||
      'missing-verification-code' => AuthFailureKind.invalidCode,
      'session-expired' ||
      'invalid-verification-id' => AuthFailureKind.codeExpired,
      'too-many-requests' ||
      'quota-exceeded' => AuthFailureKind.tooManyRequests,
      'network-request-failed' => AuthFailureKind.network,
      _ => AuthFailureKind.unknown,
    }, '${e.code}: ${e.message}');
  }
}
