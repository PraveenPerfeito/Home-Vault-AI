import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Firebase service singletons ──────────────────────────────────────────────
// Feature providers (auth, items, etc.) depend on these, not on Firebase directly.

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
  name: 'firebaseAuth',
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
  name: 'firestore',
);
