import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/tenant_provider.dart';
import '../../services/billing_service.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantProvider>();
    final billing = BillingService(workerBaseUrl: 'https://imanagement-stripe.mokadem59200.workers.dev');
    const priceId = 'price_1SOlYFBefWQoVTT09yR9vm8Y';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans & Facturation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tenant: ${tenant.tenantId ?? '-'}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Plan actuel: ${tenant.plan}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Avantages inclus'),
                    const SizedBox(height: 8),
                    Text(tenant.entitlements.isEmpty
                        ? 'Aucun entitlement chargé (bientôt)'
                        : tenant.entitlements.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final checkoutUrl = await billing.createCheckoutSession(
                        priceId: priceId,
                        successUrl: 'https://imanagement.pages.dev/success',
                        cancelUrl: 'https://imanagement.pages.dev/cancel',
                      );
                      await launchUrl(checkoutUrl, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur Checkout: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('S’abonner (Checkout)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      // TODO: récupérer customerId du tenant lorsque disponible
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Portail client sera activé quand customerId sera disponible')),
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur portail: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.manage_accounts),
                  label: const Text('Gérer mon abonnement (Portail)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


