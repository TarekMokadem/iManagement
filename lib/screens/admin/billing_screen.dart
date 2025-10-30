import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tenant_provider.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantProvider>();

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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Portail Stripe à venir')),
                  );
                },
                child: const Text('Gérer mon abonnement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


