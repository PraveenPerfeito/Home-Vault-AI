import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final String plan; // 'free' | 'premium'
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.isAnonymous,
    required this.plan,
    required this.createdAt,
  });

  String get nameOrEmail => displayName ?? email ?? 'Guest';

  @override
  List<Object?> get props =>
      [id, email, displayName, photoUrl, isAnonymous, plan, createdAt];
}
