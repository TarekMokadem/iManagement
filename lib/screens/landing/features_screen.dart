import 'package:flutter/material.dart';

import '../../widgets/public_layout.dart';
import '../../widgets/animations/fx_text_fade_top.dart';

class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return PublicLayout(
      showBackButton: true,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeroSection(colorScheme, isMobile),
            _buildDetailedFeaturesSection(colorScheme, isMobile),
            _buildIntegrationsSection(colorScheme, isMobile),
            _buildCTASection(colorScheme, isMobile),
            _buildFooter(colorScheme, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(ColorScheme colorScheme, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: isMobile ? 60 : 100,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.15),
            colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          FxTextFadeTop(
            child: Text(
              'Fonctionnalités puissantes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 36 : 52,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tout ce dont vous avez besoin pour gérer votre stock efficacement',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedFeaturesSection(ColorScheme colorScheme, bool isMobile) {
    final features = [
      {
        'icon': Icons.inventory_2_outlined,
        'title': 'Gestion de stock en temps réel',
        'description':
            'Suivez vos produits en temps réel avec des mises à jour instantanées. Ajoutez, modifiez ou supprimez des produits en quelques clics.',
        'highlights': ['Synchronisation instantanée', 'Interface intuitive', 'Recherche rapide'],
      },
      {
        'icon': Icons.people_outline,
        'title': 'Collaboration d\'équipe',
        'description':
            'Invitez vos collaborateurs et gérez les accès selon les rôles (admin/employé). Chaque membre a son code d\'accès unique.',
        'highlights': ['Gestion des rôles', 'Codes d\'accès uniques', 'Invitations en masse'],
      },
      {
        'icon': Icons.bar_chart_outlined,
        'title': 'Statistiques et rapports',
        'description':
            'Analysez vos mouvements de stock avec des graphiques détaillés. Identifiez les tendances et optimisez votre gestion.',
        'highlights': ['Graphiques interactifs', 'Exports CSV', 'Historique complet'],
      },
      {
        'icon': Icons.notifications_active_outlined,
        'title': 'Alertes intelligentes',
        'description':
            'Recevez des notifications automatiques quand un produit atteint son seuil critique. Ne manquez jamais une rupture de stock.',
        'highlights': ['Seuils personnalisables', 'Notifications temps réel', 'Vue dédiée produits critiques'],
      },
      {
        'icon': Icons.qr_code_scanner_outlined,
        'title': 'Scanner de codes-barres',
        'description':
            'Scannez les codes-barres de vos produits pour les ajouter ou modifier rapidement. Gain de temps garanti.',
        'highlights': ['Scan instantané', 'Compatible tous formats', 'Mode hors ligne'],
      },
      {
        'icon': Icons.history_outlined,
        'title': 'Historique détaillé',
        'description':
            'Consultez l\'historique complet de toutes les opérations : ajouts, retraits, modifications. Traçabilité totale.',
        'highlights': ['Journal d\'activité', 'Filtres avancés', 'Export des données'],
      },
      {
        'icon': Icons.cloud_outlined,
        'title': 'Accès cloud',
        'description':
            'Accédez à vos données depuis n\'importe quel appareil : ordinateur, tablette ou smartphone. Vos données sont synchronisées partout.',
        'highlights': ['Multi-plateforme', 'Mode offline', 'Synchronisation auto'],
      },
      {
        'icon': Icons.security_outlined,
        'title': 'Sécurité et confidentialité',
        'description':
            'Vos données sont chiffrées de bout en bout et sauvegardées quotidiennement. Conformité RGPD garantie.',
        'highlights': ['Chiffrement AES-256', 'Sauvegardes quotidiennes', 'Conformité RGPD'],
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 72,
        vertical: isMobile ? 48 : 80,
      ),
      child: Center(
        child: ConstrainedBox(
          // On limite un peu plus la largeur pour avoir de vraies marges latérales
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: features.asMap().entries.map((entry) {
              final index = entry.key;
              final feature = entry.value;
              final isReversed = index.isOdd && !isMobile;

              return Padding(
                padding: EdgeInsets.only(bottom: isMobile ? 48 : 64),
                child: _buildFeatureRow(
                  colorScheme,
                  isMobile,
                  feature['icon'] as IconData,
                  feature['title'] as String,
                  feature['description'] as String,
                  feature['highlights'] as List<String>,
                  isReversed,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    ColorScheme colorScheme,
    bool isMobile,
    IconData icon,
    String title,
    String description,
    List<String> highlights,
    bool isReversed,
  ) {
    final iconWidget = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, size: 48, color: colorScheme.onPrimary),
    );

    final contentWidget = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: highlights.map((h) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      h,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          iconWidget,
          const SizedBox(height: 24),
          contentWidget,
        ],
      );
    }

    final children = isReversed
        ? [contentWidget, const SizedBox(width: 40), iconWidget]
        : [iconWidget, const SizedBox(width: 40), contentWidget];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildIntegrationsSection(ColorScheme colorScheme, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: isMobile ? 60 : 100,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Column(
        children: [
          Text(
            'Toujours plus de fonctionnalités',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 32 : 42,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nous ajoutons régulièrement de nouvelles fonctionnalités',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _buildComingSoonCard(colorScheme, Icons.api, 'API REST', isMobile),
              _buildComingSoonCard(colorScheme, Icons.phone_iphone, 'App mobile native', isMobile),
              _buildComingSoonCard(colorScheme, Icons.attachment, 'Import/Export Excel', isMobile),
              _buildComingSoonCard(colorScheme, Icons.mail_outline, 'Alertes email', isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonCard(ColorScheme colorScheme, IconData icon, String label, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: colorScheme.primary.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Bientôt',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection(ColorScheme colorScheme, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: isMobile ? 60 : 100,
      ),
      child: Column(
        children: [
          Text(
            'Prêt à optimiser votre gestion de stock ?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 32 : 42,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/signup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 32 : 48,
                vertical: isMobile ? 16 : 20,
              ),
              elevation: 4,
              shadowColor: colorScheme.primary.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Commencer gratuitement',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme colorScheme, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2, color: colorScheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'iManagement',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (!isMobile)
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/legal'),
                      child: const Text('Mentions légales'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/pricing'),
                      child: const Text('Tarifs'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '© 2024 iManagement. Tous droits réservés.',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

