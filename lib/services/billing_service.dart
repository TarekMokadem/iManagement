import 'dart:convert';

import 'package:http/http.dart' as http;

class BillingService {
  final String workerBaseUrl;

  BillingService({required this.workerBaseUrl});

  Future<Uri> createCheckoutSession({
    required String priceId,
    required String successUrl,
    required String cancelUrl,
    String? customerId,
  }) async {
    final url = Uri.parse('$workerBaseUrl/checkout/session');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'priceId': priceId,
        'successUrl': successUrl,
        'cancelUrl': cancelUrl,
        if (customerId != null) 'customerId': customerId,
      }),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final urlString = (data['url'] ?? data['session']?['url']) as String?;
      if (urlString == null) {
        throw Exception('Réponse Stripe invalide (pas d\'URL)');
      }
      return Uri.parse(urlString);
    }
    throw Exception('Erreur création session Checkout: ${resp.statusCode} ${resp.body}');
  }

  Future<Uri> createPortalSession({
    required String customerId,
    required String returnUrl,
  }) async {
    final url = Uri.parse('$workerBaseUrl/billing/portal');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customerId': customerId,
        'returnUrl': returnUrl,
      }),
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final urlString = (data['url'] ?? data['session']?['url']) as String?;
      if (urlString == null) {
        throw Exception('Réponse Stripe invalide (pas d\'URL)');
      }
      return Uri.parse(urlString);
    }
    throw Exception('Erreur création session Portal: ${resp.statusCode} ${resp.body}');
  }
}


