import 'dart:async';

import 'package:progressbar_app/data/auth_repository.dart';
import 'package:progressbar_app/data/profile_repository.dart';
import 'package:progressbar_app/domain/models.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.validCode = '123456', String? signedInAs})
    : _uid = signedInAs;

  final String validCode;
  final _changes = StreamController<String?>.broadcast();
  String? _uid;
  String? sentTo;
  int sendCount = 0;

  @override
  Stream<String?> get uid async* {
    yield _uid;
    yield* _changes.stream;
  }

  @override
  String? get phoneNumber => _uid == null ? null : sentTo;

  @override
  Future<void> sendCode(String phone) async {
    if (!phone.startsWith('+7')) {
      throw const AuthFailure(AuthFailureKind.invalidPhone);
    }
    sentTo = phone;
    sendCount++;
  }

  @override
  Future<void> confirmCode(String smsCode) async {
    if (smsCode != validCode) {
      throw const AuthFailure(AuthFailureKind.invalidCode);
    }
    _changes.add(_uid = 'user-1');
  }

  @override
  Future<void> signOut() async => _changes.add(_uid = null);
}

class FakeProfileRepository implements ProfileRepository {
  final _profiles = <String, UserProfile>{};
  final _changes = StreamController<String>.broadcast();

  UserProfile? profileOf(String uid) => _profiles[uid];

  @override
  Stream<UserProfile?> watch(String uid) async* {
    yield _profiles[uid];
    yield* _changes.stream.where((id) => id == uid).map((id) => _profiles[id]);
  }

  @override
  Future<void> save(UserProfile profile) async {
    _profiles[profile.id] = profile;
    _changes.add(profile.id);
  }
}
