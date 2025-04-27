import 'package:flutter/material.dart';
import '../../services/operation_service.dart';
import '../../models/operation.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  final OperationService _operationService = OperationService();
  final String userId;

  HistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des opérations'),
      ),
      body: StreamBuilder<List<Operation>>(
        stream: _operationService.getAllOperations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement de l\'historique\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Force un rechargement
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement de l\'historique...'),
                ],
              ),
            );
          }

          final operations = snapshot.data!;

          if (operations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune opération enregistrée'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: operations.length,
            itemBuilder: (context, index) {
              final operation = operations[index];
              final isEntry = operation.type == OperationType.entry;
              
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: ListTile(
                  leading: Icon(
                    isEntry ? Icons.add_circle : Icons.remove_circle,
                    color: isEntry ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  title: Text(
                    operation.productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantité: ${operation.quantity}',
                        style: TextStyle(
                          color: isEntry ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(operation.timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isEntry ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      operation.typeString.toUpperCase(),
                      style: TextStyle(
                        color: isEntry ? Colors.green.shade900 : Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 