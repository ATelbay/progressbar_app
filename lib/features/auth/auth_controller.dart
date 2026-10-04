import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder until phone sign-in is wired to the server.
class AuthController extends Notifier<bool> {
  @override
  bool build() => false;

  void signIn() => state = true;

  void signOut() => state = false;
}

final authControllerProvider = NotifierProvider<AuthController, bool>(
  AuthController.new,
);
