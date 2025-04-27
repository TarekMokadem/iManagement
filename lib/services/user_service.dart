import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Récupérer tous les utilisateurs
  Stream<List<AppUser>> getAllUsers() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return AppUser.fromMap(data);
            })
            .toList());
  }

  // Récupérer un utilisateur par son code
  Future<AppUser?> getUserByCode(String code) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('code', isEqualTo: code)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    final data = doc.data();
    data['id'] = doc.id;
    return AppUser.fromMap(data);
  }

  // Ajouter un nouvel utilisateur
  Future<void> addUser(AppUser user) async {
    await _firestore.collection(_collection).add(user.toMap());
  }

  // Mettre à jour un utilisateur
  Future<void> updateUser(String userId, AppUser user) async {
    await _firestore.collection(_collection).doc(userId).update(user.toMap());
  }

  // Supprimer un utilisateur
  Future<void> deleteUser(String userId) async {
    await _firestore.collection(_collection).doc(userId).delete();
  }

  // Vérifier si un code est déjà utilisé
  Future<bool> isCodeAvailable(String code) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('code', isEqualTo: code)
        .get();
    return snapshot.docs.isEmpty;
  }

  // Récupérer les administrateurs
  Stream<List<AppUser>> getAdmins() {
    return _firestore
        .collection(_collection)
        .where('isAdmin', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return AppUser.fromMap(data);
      }).toList();
    });
  }
} 