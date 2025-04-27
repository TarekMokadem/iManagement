import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AppUser> login(String code) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Code invalide');
    }

    final userDoc = querySnapshot.docs.first;
    return AppUser.fromMap(userDoc.data()..['id'] = userDoc.id);
  }
} 