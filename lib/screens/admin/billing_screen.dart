import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bannière d'alerte paiement
            if (tenant.hasPaymentIssue)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Problème de paiement',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                          ),
                          if (tenant.billingLastPaymentError != null)
                            Text(tenant.billingLastPaymentError!, style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 4),
                          const Text(
                            'Veuillez mettre à jour votre moyen de paiement ci-dessous.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Statut abonnement
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Plan actuel', style: Theme.of(context).textTheme.titleLarge),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: tenant.plan == 'pro' ? Colors.blue.shade100 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            tenant.plan.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tenant.plan == 'pro' ? Colors.blue.shade900 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (tenant.billingCurrentPeriodEnd != null)
                      Text(
                        'Renouvellement le ${DateFormat.yMMMMd('fr_FR').format(tenant.billingCurrentPeriodEnd!)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    if (tenant.entitlements.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text('Votre abonnement inclut :', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...tenant.entitlements.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Text('${e.key}: ${e.value}'),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tableau comparatif
            const Text('Comparer les plans', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Fonctionnalité', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Free', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Pro', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ],
                ),
                _buildComparisonRow('Utilisateurs', '3', '20'),
                _buildComparisonRow('Produits', '200', '10 000'),
                _buildComparisonRow('Opérations/mois', '1 000', '100 000'),
                _buildComparisonRow('Exports', '✓', '✓'),
                _buildComparisonRow('Support', 'Community', 'Priority'),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (tenant.plan == 'free')
                  ElevatedButton.icon(
                    onPressed: tenant.tenantId == null || _isCreatingCheckout
                        ? null
                        : () async {
                            setState(() => _isCreatingCheckout = true);
                      try {
                        final tenantId = tenant.tenantId!;
                        final existingCustomerId = tenant.stripeCustomerId ??
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.upgrade),
                    label: _isCreatingCheckout
                        ? const Text('Création en cours...')
                        : const Text('Passer au plan Pro'),
                  ),
                if (tenant.plan == 'free') const SizedBox(height: 8),
                if (tenant.stripeCustomerId != null)
                  ElevatedButton.icon(
                    onPressed: tenant.tenantId == null || _isOpeningPortal
                        ? null
                        : () async {
                            setState(() => _isOpeningPortal = true);
                      try {
                        final customerId = tenant.stripeCustomerId ??
                            await tenantService.getStripeCustomerId(tenant.tenantId!);
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
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

  TableRow _buildComparisonRow(String feature, String freeValue, String proValue) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(feature),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(freeValue, textAlign: TextAlign.center),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(proValue, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}


