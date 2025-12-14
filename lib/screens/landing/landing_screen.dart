import 'package:flutter/material.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SelectionArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildAppBar(colorScheme, isMobile),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHeroSection(colorScheme, isMobile),
                  _buildSocialProofSection(colorScheme, isMobile),
                  KeyedSubtree(
                    key: _featuresKey,
                    child: _buildFeaturesSection(colorScheme, isMobile),
                  ),
                  _buildHowItWorksSection(colorScheme, isMobile),
                  KeyedSubtree(
                    key: _pricingKey,
                    child: _buildPricingSection(colorScheme, isMobile),
                  ),
                  _buildFAQSection(colorScheme, isMobile),
                  _buildCTASection(colorScheme, isMobile),
                  _buildFooter(colorScheme, isMobile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme, bool isMobile) {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
      title: Row(
        children: [
          Icon(Icons.inventory_2, color: colorScheme.primary, size: 28),
          const SizedBox(width: 8),
          Text(
            'iManagement',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        if (!isMobile) ...[
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/features'),
            child: const Text('Fonctionnalités'),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/pricing'),
            child: const Text('Tarifs'),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/tenant-login'),
            child: const Text('Connexion'),
          ),
          const SizedBox(width: 8),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/signup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Essai gratuit',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(ColorScheme colorScheme, bool isMobile) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 64,
            vertical: isMobile ? 60 : 120,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer.withValues(alpha: 0.2),
                colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Nouveau : Plan Pro avec support prioritaire',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Gérez votre stock\navec simplicité',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 36 : 56,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'La solution de gestion de stock pensée pour les PME.\nSimple, rapide, et accessible depuis n\'importe où.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
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
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/features'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 32 : 48,
                        vertical: isMobile ? 16 : 20,
                      ),
                      side: BorderSide(color: colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Découvrir les fonctionnalités',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24 : 32,
                        vertical: 16,
                      ),
                    ),
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text(
                      'Voir la démo',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Pas de carte bancaire requise',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Essai gratuit 14 jours',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialProofSection(ColorScheme colorScheme, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: isMobile ? 40 : 60,
      ),
      child: Column(
        children: [
          Text(
            'Ils nous font confiance',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 48,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildStatCard(colorScheme, '500+', 'Entreprises'),
              _buildStatCard(colorScheme, '10k+', 'Produits gérés'),
              _buildStatCard(colorScheme, '50k+', 'Opérations/mois'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(ColorScheme colorScheme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(ColorScheme colorScheme, bool isMobile) {
    final features = [
      {
        'icon': Icons.inventory_2,
        'title': 'Gestion de stock intuitive',
        'description':
            'Suivez vos produits en temps réel avec une interface simple et rapide.',
      },
      {
        'icon': Icons.people,
        'title': 'Collaboration d\'équipe',
        'description':
            'Invitez vos collaborateurs et gérez les accès selon les rôles.',
      },
      {
        'icon': Icons.bar_chart,
        'title': 'Statistiques avancées',
        'description':
            'Analysez vos mouvements de stock et anticipez vos besoins.',
      },
      {
        'icon': Icons.warning,
        'title': 'Alertes automatiques',
        'description':
            'Recevez des notifications quand un produit atteint son seuil critique.',
      },
      {
        'icon': Icons.cloud,
        'title': '100% Cloud',
        'description':
            'Accédez à vos données depuis n\'importe quel appareil, n\'importe où.',
      },
      {
        'icon': Icons.security,
        'title': 'Sécurité garantie',
        'description':
            'Vos données sont chiffrées et sauvegardées automatiquement.',
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: isMobile ? 60 : 100,
      ),
      child: Column(
        children: [
          Text(
            'Tout ce dont vous avez besoin',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 32 : 42,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Des fonctionnalités pensées pour simplifier votre quotidien',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 64),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: isMobile ? 3 : 1.2,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return _buildFeatureCard(
                colorScheme,
                feature['icon'] as IconData,
                feature['title'] as String,
                feature['description'] as String,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    ColorScheme colorScheme,
    IconData icon,
    String title,
    String description,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksSection(ColorScheme colorScheme, bool isMobile) {
    final steps = [
      {
        'number': '1',
        'title': 'Créez votre compte',
        'description': 'Inscription en 30 secondes, sans carte bancaire',
      },
      {
        'number': '2',
        'title': 'Ajoutez vos produits',
        'description': 'Importez ou créez vos produits en quelques clics',
      },
      {
        'number': '3',
        'title': 'Invitez votre équipe',
        'description': 'Collaborez avec vos employés en temps réel',
      },
    ];

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
            'Comment ça marche ?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 32 : 42,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 64),
          ...steps.map((step) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        step['number'] as String,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title'] as String,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step['description'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPricingSection(ColorScheme colorScheme, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: isMobile ? 60 : 100,
      ),
      child: Column(
        children: [
          Text(
            'Tarifs simples et transparents',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 32 : 42,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Commencez gratuitement, évoluez quand vous voulez',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 64),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildPricingCard(
                colorScheme,
                'Free',
                '0€',
                '/mois',
                'Pour démarrer',
                [
                  '3 utilisateurs',
                  '200 produits',
                  '1 000 opérations/mois',
                  'Support communautaire',
                ],
                false,
                isMobile,
              ),
              _buildPricingCard(
                colorScheme,
                'Pro',
                '29€',
                '/mois',
                'Pour les équipes',
                [
                  '20 utilisateurs',
                  '10 000 produits',
                  '100 000 opérations/mois',
                  'Support prioritaire',
                  'Exports avancés',
                ],
                true,
                isMobile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(
    ColorScheme colorScheme,
    String name,
    String price,
    String period,
    String subtitle,
    List<String> features,
    bool isPopular,
    bool isMobile,
  ) {
    return Container(
      width: isMobile ? double.infinity : 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isPopular
            ? colorScheme.primaryContainer.withValues(alpha: 0.1)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.2),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'POPULAIRE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                  letterSpacing: 1,
                ),
              ),
            ),
          if (isPopular) const SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  period,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPopular ? colorScheme.primary : colorScheme.surface,
                foregroundColor:
                    isPopular ? colorScheme.onPrimary : colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: isPopular ? 2 : 0,
                side: isPopular ? null : BorderSide(color: colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Commencer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFAQSection(ColorScheme colorScheme, bool isMobile) {
    final faqs = [
      {
        'question': 'Ai-je besoin d\'une carte bancaire pour l\'essai gratuit ?',
        'answer':
            'Non, vous pouvez commencer avec le plan Free sans aucune carte bancaire. Vous pourrez passer au plan Pro quand vous le souhaitez.',
      },
      {
        'question': 'Puis-je changer de plan à tout moment ?',
        'answer':
            'Oui, vous pouvez passer du plan Free au plan Pro (ou inversement) à tout moment depuis votre espace de facturation.',
      },
      {
        'question': 'Mes données sont-elles sécurisées ?',
        'answer':
            'Absolument. Vos données sont chiffrées, sauvegardées quotidiennement et hébergées sur des serveurs sécurisés conformes RGPD.',
      },
      {
        'question': 'Puis-je annuler mon abonnement ?',
        'answer':
            'Oui, vous pouvez annuler votre abonnement à tout moment. Vous conserverez l\'accès jusqu\'à la fin de votre période de facturation.',
      },
    ];

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
            'Questions fréquentes',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 32 : 42,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 64),
          ...faqs.map((faq) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ExpansionTile(
                  title: Text(
                    faq['question'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        faq['answer'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Prêt à simplifier votre gestion de stock ?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 32 : 42,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Rejoignez des centaines d\'entreprises qui font confiance à iManagement',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 48),
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
        vertical: 40,
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
                      onPressed: () => Navigator.pushNamed(context, '/features'),
                      child: const Text('Fonctionnalités'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/pricing'),
                      child: const Text('Tarifs'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),
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

