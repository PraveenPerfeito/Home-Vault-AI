import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:home_vault/features/auth/domain/entities/app_user.dart';

class UserModel {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final String plan;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.isAnonymous,
    required this.plan,
    required this.createdAt,
  });

  factory UserModel.fromFirebaseUser(User user) => UserModel(
        id: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
        isAnonymous: user.isAnonymous,
        plan: 'free',
        createdAt: DateTime.now(),
      );

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) =>
      UserModel(
        id: id,
        email: data['email'] as String?,
        displayName: data['displayName'] as String?,
        photoUrl: data['photoUrl'] as String?,
        isAnonymous: (data['isAnonymous'] as bool?) ?? false,
        plan: (data['plan'] as String?) ?? 'free',
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'isAnonymous': isAnonymous,
        'plan': plan,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  AppUser toEntity() => AppUser(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        isAnonymous: isAnonymous,
        plan: plan,
        createdAt: createdAt,
      );
}
