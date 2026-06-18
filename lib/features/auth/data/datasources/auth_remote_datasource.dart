import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:home_vault/core/error/app_exception.dart';
import 'package:home_vault/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDatasource {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel> signInWithEmail({required String email, required String password});
  Future<UserModel> signUpWithEmail({required String email, required String password, required String displayName});
  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInAnonymously();
  Future<void> signOut();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDatasourceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _auth = auth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  @override
  Stream<UserModel?> get authStateChanges =>
      _auth.authStateChanges().asyncMap((user) async {
        if (user == null) return null;
        return _getOrCreateUserDoc(user);
      });

  Future<UserModel> _getOrCreateUserDoc(User firebaseUser) async {
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final snap = await docRef.get();

    if (snap.exists && snap.data() != null) {
      return UserModel.fromFirestore(snap.data()!, snap.id);
    }

    // First sign-in: create the user document.
    final newUser = UserModel.fromFirebaseUser(firebaseUser);
    await docRef.set(newUser.toFirestore());
    return newUser;
  }

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // H4: explicit null check — cred.user can theoretically be null on edge-case flows.
      final user = cred.user;
      if (user == null) throw const AuthException('Sign-in failed. Please try again.');
      return _getOrCreateUserDoc(user);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authMessage(e.code), cause: e);
    }
  }

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // H4: explicit null checks — avoid bang operator on user and currentUser.
      final user = cred.user;
      if (user == null) throw const AuthException('Sign-up failed. Please try again.');
      await user.updateDisplayName(displayName);
      await user.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) throw const AuthException('Sign-up failed. Please try again.');
      return _getOrCreateUserDoc(refreshedUser);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authMessage(e.code), cause: e);
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw const AuthException('Google sign-in was cancelled.');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      // H4: explicit null check.
      final user = cred.user;
      if (user == null) throw const AuthException('Google sign-in failed. Please try again.');
      return _getOrCreateUserDoc(user);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authMessage(e.code), cause: e);
    } catch (e) {
      throw AuthException('Google sign-in failed.', cause: e);
    }
  }

  @override
  Future<UserModel> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      // H4: explicit null check.
      final user = cred.user;
      if (user == null) throw const AuthException('Guest sign-in failed. Please try again.');
      return _getOrCreateUserDoc(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authMessage(e.code), cause: e);
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // H11: user-not-found and wrong-password (and invalid-credential on newer SDK) return
  // the same message to prevent account enumeration attacks.
  String _authMessage(String code) => switch (code) {
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'Email or password is incorrect.',
        'email-already-in-use' => 'An account already exists with this email.',
        'invalid-email' => 'Please enter a valid email address.',
        'weak-password' => 'Password must be at least 6 characters.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' => 'Check your internet connection.',
        _ => 'Authentication failed. Please try again.',
      };
}
