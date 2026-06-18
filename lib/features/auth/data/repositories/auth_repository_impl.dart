import 'package:home_vault/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:home_vault/features/auth/domain/entities/app_user.dart';
import 'package:home_vault/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepositoryImpl({required AuthRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Stream<AppUser?> get authStateChanges =>
      _datasource.authStateChanges.map((model) => model?.toEntity());

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final model = await _datasource.signInWithEmail(
      email: email,
      password: password,
    );
    return model.toEntity();
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final model = await _datasource.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
    return model.toEntity();
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final model = await _datasource.signInWithGoogle();
    return model.toEntity();
  }

  @override
  Future<AppUser> signInAnonymously() async {
    final model = await _datasource.signInAnonymously();
    return model.toEntity();
  }

  @override
  Future<void> signOut() => _datasource.signOut();
}
