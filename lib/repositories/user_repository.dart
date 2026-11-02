import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // حفظ مستخدم جديد
  Future<void> createUser(UserModel user) async {
    await _users.doc(user.id).set(
      user.toMap(),
    );
  }

  // جلب مستخدم بواسطة ID
  Future<UserModel?> getUser(String userId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _users.doc(userId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return UserModel.fromMap(
      snapshot.id,
      snapshot.data()!,
    );
  }

  // تحديث بيانات المستخدم
  Future<void> updateUser(UserModel user) async {
    await _users.doc(user.id).set(
      user.toMap(),
      SetOptions(merge: true),
    );
  }
}