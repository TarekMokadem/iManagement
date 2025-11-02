import '../models/operation.dart';

abstract class OperationsRepository {
  Stream<List<Operation>> watchAll({required String tenantId});
  Stream<List<Operation>> watchByDate(DateTime date, {required String tenantId});
  Stream<List<Operation>> watchByType(OperationType type, {required String tenantId});
  Stream<List<Operation>> watchByProduct(String productId, {required String tenantId});
  Stream<List<Operation>> watchByUser(String userId, {required String tenantId});
  Future<void> add(Operation operation, {required String tenantId});
  Future<void> delete(String id, {required String tenantId});
}
