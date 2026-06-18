import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:home_vault/core/di/providers.dart';
import 'package:home_vault/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:home_vault/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:home_vault/features/auth/domain/entities/app_user.dart';
import 'package:home_vault/features/auth/domain/repositories/auth_repository.dart';

// ── Infrastructure ──────────────────────────────────────────────────────────

final googleSignInProvider = Provider<GoogleSignIn>(
  (_) => GoogleSignIn(scopes: ['email']),
);

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasourceImpl(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    datasource: ref.watch(authRemoteDatasourceProvider),
  );
});

// ── Auth State ──────────────────────────────────────────────────────────────

/// Authoritative auth stream. Emits [AppUser?] on every auth change.
final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

/// Convenience accessor — null when signed out or loading.
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

// ── Auth Actions ────────────────────────────────────────────────────────────

final authActionsProvider =
    AutoDisposeAsyncNotifierProvider<AuthActionsNotifier, void>(
  AuthActionsNotifier.new,
);

class AuthActionsNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.signInWithEmail(email: email, password: password);
    });
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.signInWithGoogle);
  }

  Future<void> signInAnonymously() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.signInAnonymously);
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.signOut);
  }
}
