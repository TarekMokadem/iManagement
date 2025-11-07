import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/alert.dart';

class AlertHistoryScreen extends StatelessWidget {
  const AlertHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Alertes'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final alerts = snapshot.data?.docs
              .map((doc) => Alert.fromFirestore(doc))
              .toList() ?? [];

          if (alerts.isEmpty) {
            return const Center(
              child: Text('Aucune alerte enregistrée'),
            );
          }

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: Icon(
                    alert.status == 'pending'
                        ? Icons.warning
                        : Icons.check_circle,
                    color: alert.status == 'pending'
                        ? Colors.orange
                        : Colors.green,
                  ),
                  title: Text(alert.notification['title'] ?? 'Alerte'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert.notification['body'] ?? ''),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(alert.timestamp)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'mark_resolved') {
                        await FirebaseFirestore.instance
                            .collection('alerts')
                            .doc(alert.id)
                            .update({'status': 'resolved'});
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'mark_resolved',
                        child: Text('Marquer comme résolu'),
                      ),
                    ],
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