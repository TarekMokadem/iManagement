import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // Demander l'autorisation pour les notifications
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configurer les gestionnaires de messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Message reçu en premier plan: ${message.notification?.title}');
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Message reçu en arrière-plan: ${message.notification?.title}');
  }

  Future<void> checkCriticalProducts() async {
    final products = await _firestore.collection('products').get();
    
    for (var doc in products.docs) {
      final data = doc.data();
      final quantity = data['quantity'] as int? ?? 0;
      final criticalThreshold = data['criticalThreshold'] as int? ?? 0;
      
      if (quantity <= criticalThreshold) {
        await _sendCriticalAlert(doc.id, data['name'] as String? ?? 'Produit inconnu');
      }
    }
  }

  Future<void> _sendCriticalAlert(String productId, String productName) async {
    // Vérifier si une alerte a déjà été envoyée récemment
    final lastAlert = await _firestore
        .collection('alerts')
        .where('productId', isEqualTo: productId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (lastAlert.docs.isNotEmpty) {
      final lastAlertTime = lastAlert.docs.first.data()['timestamp'] as Timestamp;
      final now = DateTime.now();
      final difference = now.difference(lastAlertTime.toDate());
      
      // Ne pas envoyer d'alerte si la dernière alerte date de moins de 24h
      if (difference.inHours < 24) {
        return;
      }
    }

    // Enregistrer l'alerte dans Firestore
    await _firestore.collection('alerts').add({
      'productId': productId,
      'productName': productName,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'notification': {
        'title': 'Alerte Produit Critique',
        'body': 'Le produit $productName a atteint son seuil critique',
      },
    });

    // S'abonner au topic pour recevoir les notifications
    await _messaging.subscribeToTopic('critical_products');
  }
} 