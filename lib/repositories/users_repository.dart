import '../models/user.dart';

abstract class UsersRepository {
  Stream<List<AppUser>> watchUsers({String? tenantId});
  Future<void> addUser(AppUser user, {required String tenantId});
  Future<void> updateUser(String userId, AppUser user, {required String tenantId});
  Future<void> deleteUser(String userId, {required String tenantId});
  Future<bool> isCodeAvailable(String code, {required String tenantId});
}


