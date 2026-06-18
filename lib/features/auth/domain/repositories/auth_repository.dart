import 'package:home_vault/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  /// Emits the current user on every auth state change.
  /// Emits [null] when signed out.
  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AppUser> signInWithGoogle();

  Future<AppUser> signInAnonymously();

  Future<void> signOut();
}
