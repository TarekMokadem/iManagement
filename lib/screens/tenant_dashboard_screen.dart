import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../providers/tenant_provider.dart';
import '../services/session_service.dart';
import '../services/tenant_service.dart';
import 'admin/billing_screen.dart';

class TenantDashboardScreen extends StatelessWidget {
  TenantDashboardScreen({super.key});

  final TenantService _tenantService = TenantService();

  Future<void> _handleLogout(BuildContext context) async {
    final sessionProvider = context.read<SessionProvider>();
    final tenantProvider = context.read<TenantProvider>();
    final navigator = Navigator.of(context);

    await sessionProvider.logout();
    tenantProvider.clearTenant();
    await navigator.pushNamedAndRemoveUntil('/tenant-login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tenantProvider = context.watch<TenantProvider>();
    final session = context.watch<SessionProvider>().session;
    final tenantId = tenantProvider.tenantId;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Espace client'),
        actions: [
          TextButton.icon(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Déconnexion'),
          ),
        ],
      ),
      body: tenantId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<Map<String, dynamic>?>(
              stream: _tenantService.watchTenant(tenantId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tenantData = snapshot.data;
                return SelectionArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroCard(context, colorScheme, tenantProvider, tenantData),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 900) {
                              return Column(
                                children: [
                                  _buildProfileCard(colorScheme, session, tenantProvider, tenantData),
                                  const SizedBox(height: 16),
                                  _buildPlanCard(context, colorScheme, tenantProvider),
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildProfileCard(colorScheme, session, tenantProvider, tenantData)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildPlanCard(context, colorScheme, tenantProvider)),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildEntitlementsSection(colorScheme, tenantProvider),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    ColorScheme colorScheme,
    TenantProvider tenant,
    Map<String, dynamic>? tenantData,
  ) {
    final company = (tenantData?['name'] as String?) ?? 'Votre organisation';
    final createdAt = (tenantData?['createdAt'] as Timestamp?)?.toDate();
    final subtitle = createdAt != null
        ? 'Client depuis le ${MaterialLocalizations.of(context).formatFullDate(createdAt)}'
        : 'Bienvenue dans votre espace client';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.4),
            colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            company,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildHeroChip(colorScheme, Icons.workspace_premium, tenant.plan.toUpperCase()),
              _buildHeroChip(
                colorScheme,
                tenant.hasPaymentIssue ? Icons.warning_amber : Icons.verified_user,
                tenant.hasPaymentIssue ? 'Paiement à vérifier' : 'Facturation active',
                background: tenant.hasPaymentIssue ? Colors.redAccent : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(ColorScheme scheme, IconData icon, String label, {Color? background}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: background ?? scheme.onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.onPrimary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    ColorScheme scheme,
    SessionData? session,
    TenantProvider tenant,
    Map<String, dynamic>? tenantData,
  ) {
    final sanitizedName = (session?.userName ?? '').trim();
    final initials = sanitizedName.isNotEmpty ? sanitizedName[0].toUpperCase() : 'U';
    final billingStatus = tenant.billingStatus;
    final contactEmail = (tenantData?['contactEmail'] as String?) ?? (tenantData?['email'] as String?) ?? 'Non renseigné';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.person_outline, 'Profil', scheme),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: scheme.primary.withValues(alpha: 0.1),
              child: Text(initials, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(session?.userName ?? 'Utilisateur'),
            subtitle: Text(contactEmail),
          ),
          const Divider(),
          _profileRow('Identifiant tenant', session?.tenantId ?? '—'),
          const SizedBox(height: 8),
          _profileRow('Statut facturation', billingStatus),
        ],
      ),
    );
  }

  Widget _cardHeader(IconData icon, String title, ColorScheme scheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: scheme.onSurface),
        ),
      ],
    );
  }

  Widget _profileRow(String label, String value, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ],
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    ColorScheme scheme,
    TenantProvider tenant,
  ) {
    final periodEnd = tenant.billingCurrentPeriodEnd;
    final hasIssue = tenant.hasPaymentIssue;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.workspace_premium_outlined, 'Plan & facturation', scheme),
          const SizedBox(height: 16),
          Text(
            tenant.plan.toUpperCase(),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            hasIssue
                ? tenant.billingLastPaymentError ?? 'Action requise'
                : 'Facturation active${periodEnd != null ? ' • Renouvellement ${MaterialLocalizations.of(context).formatMediumDate(periodEnd)}' : ''}',
            style: TextStyle(color: hasIssue ? Colors.red : scheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _planPill(Icons.people_alt_outlined, '${tenant.maxUsers ?? '∞'} utilisateurs'),
              _planPill(Icons.inventory_2_outlined, '${tenant.maxProducts ?? '∞'} produits'),
              _planPill(Icons.swap_vert, '${tenant.maxOperationsPerMonth ?? '∞'} opérations/mois'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(builder: (_) => const BillingScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                  ),
                  child: const Text('Gérer mon abonnement'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/admin'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Accéder à l’application'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _planPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey.shade700),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEntitlementsSection(ColorScheme scheme, TenantProvider tenant) {
    final entitlements = <Map<String, dynamic>>[
      {
        'icon': Icons.analytics_outlined,
        'title': 'Statistiques',
        'description': 'Visibilité sur vos mouvements',
      },
      {
        'icon': Icons.file_present_outlined,
        'title': 'Exports',
        'description': (tenant.entitlements['exports'] == true || tenant.entitlements['exports'] == 'true')
            ? 'Exports avancés activés'
            : 'Inclus dans le plan Pro',
      },
      {
        'icon': Icons.support_agent_outlined,
        'title': 'Support',
        'description': tenant.entitlements['support'] ?? 'Community',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vos avantages',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: scheme.onSurface),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: entitlements.map((item) {
            return Container(
              width: 280,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item['icon'] as IconData, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['description'] as String,
                          style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

