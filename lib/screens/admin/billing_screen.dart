import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/tenant_provider.dart';
import '../../services/billing_service.dart';
import '../../services/tenant_service.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  bool _isCreatingCheckout = false;
  bool _isOpeningPortal = false;

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantProvider>();
    final billing = BillingService(workerBaseUrl: 'https://imanagement-stripe.mokadem59200.workers.dev');
    final tenantService = TenantService();
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
            if (tenant.entitlements.isNotEmpty)
              Card(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Votre abonnement', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(tenant.entitlements.entries.map((e) => '• ${e.key}: ${e.value}').join('\n')),
                    ],
                  ),
                ),
              ),
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
                  onPressed: tenant.tenantId == null || _isCreatingCheckout
                      ? null
                      : () async {
                          setState(() => _isCreatingCheckout = true);
                    try {
                      final tenantId = tenant.tenantId!;
                      final existingCustomerId =
                          await tenantService.getStripeCustomerId(tenantId);
                      final checkoutUrl = await billing.createCheckoutSession(
                        priceId: priceId,
                        successUrl: 'https://imanagement.pages.dev/success',
                        cancelUrl: 'https://imanagement.pages.dev/cancel',
                        tenantId: tenantId,
                        customerId: existingCustomerId,
                      );
                      await launchUrl(checkoutUrl, webOnlyWindowName: '_self');
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur Checkout: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isCreatingCheckout = false);
                    }
                  },
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: _isCreatingCheckout
                      ? const Text('Création en cours...')
                      : const Text('S’abonner (Checkout)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: tenant.tenantId == null || _isOpeningPortal
                      ? null
                      : () async {
                          setState(() => _isOpeningPortal = true);
                    try {
                      final customerId = await tenantService.getStripeCustomerId(tenant.tenantId!);
                      if (customerId == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Aucun customer Stripe associé au tenant')),
                          );
                        }
                        return;
                      }
                      final portalUrl = await billing.createPortalSession(
                        customerId: customerId,
                        returnUrl: 'https://imanagement.pages.dev/billing',
                      );
                      await launchUrl(portalUrl, webOnlyWindowName: '_self');
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur portail: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isOpeningPortal = false);
                    }
                  },
                  icon: const Icon(Icons.manage_accounts),
                  label: _isOpeningPortal
                      ? const Text('Ouverture du portail...')
                      : const Text('Gérer mon abonnement (Portail)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


