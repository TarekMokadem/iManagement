import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/billing_invoice.dart';

class BillingService {
  final String workerBaseUrl;

  BillingService({required this.workerBaseUrl});

  Future<Uri> createCheckoutSession({
    required String priceId,
    required String successUrl,
    required String cancelUrl,
    required String tenantId,
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
        'tenantId': tenantId,
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

  Future<List<BillingInvoice>> fetchInvoices({
    required String customerId,
    int limit = 10,
    String? startingAfter,
  }) async {
    final url = Uri.parse('$workerBaseUrl/billing/invoices');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customerId': customerId,
        'limit': limit,
        if (startingAfter != null) 'startingAfter': startingAfter,
      }),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final invoices = (data['data'] as List<dynamic>? ?? [])
          .map((invoice) => BillingInvoice.fromJson(invoice as Map<String, dynamic>))
          .toList();
      return invoices;
    }

    throw Exception('Erreur récupération factures: ${resp.statusCode} ${resp.body}');
  }
}


