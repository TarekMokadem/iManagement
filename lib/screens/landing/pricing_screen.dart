import 'package:flutter/material.dart';

import '../../widgets/public_layout.dart';
import '../../widgets/animations/fx_text_fade_top.dart';
import '../../widgets/animations/fx_lazy_fade_in.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isAnnual = false;

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
            _buildPricingSection(colorScheme, isMobile),
            _buildComparisonSection(colorScheme, isMobile),
            _buildFAQSection(colorScheme, isMobile),
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
              'Tarifs simples et transparents',
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
            'Commencez gratuitement, évoluez quand vous voulez',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton('Mensuel', !_isAnnual, colorScheme),
                _buildToggleButton('Annuel (-20%)', _isAnnual, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => setState(() => _isAnnual = label.contains('Annuel')),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildPricingSection(ColorScheme colorScheme, bool isMobile) {
    final freePrice = '0€';
    final proPrice = _isAnnual ? '23€' : '29€';
    final freePeriod = '/mois';
    final proPeriod = _isAnnual ? '/mois (facturé 276€/an)' : '/mois';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: isMobile ? 60 : 100,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (isMobile) {
                return Column(
                  children: [
                    FxLazyFadeIn(
                      duration: const Duration(milliseconds: 900),
                      child: _buildPricingCard(
                        colorScheme,
                        'Free',
                        freePrice,
                        freePeriod,
                        'Pour démarrer',
                        [
                          '3 utilisateurs',
                          '200 produits',
                          '1 000 opérations/mois',
                          'Support communautaire',
                          'Accès Web',
                        ],
                        false,
                        true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FxLazyFadeIn(
                      duration: const Duration(milliseconds: 900),
                      child: _buildPricingCard(
                        colorScheme,
                        'Pro',
                        proPrice,
                        proPeriod,
                        'Pour les équipes',
                        [
                          '20 utilisateurs',
                          '10 000 produits',
                          '100 000 opérations/mois',
                          'Support prioritaire',
                          'Exports avancés (CSV)',
                          'Historique illimité',
                          'Scanner codes-barres',
                          'Alertes personnalisées',
                        ],
                        true,
                        true,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FxLazyFadeIn(
                      duration: const Duration(milliseconds: 900),
                      child: _buildPricingCard(
                        colorScheme,
                        'Free',
                        freePrice,
                        freePeriod,
                        'Pour démarrer',
                        [
                          '3 utilisateurs',
                          '200 produits',
                          '1 000 opérations/mois',
                          'Support communautaire',
                          'Accès Web',
                        ],
                        false,
                        false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Flexible(
                    child: FxLazyFadeIn(
                      duration: const Duration(milliseconds: 900),
                      child: _buildPricingCard(
                        colorScheme,
                        'Pro',
                        proPrice,
                        proPeriod,
                        'Pour les équipes',
                        [
                          '20 utilisateurs',
                          '10 000 produits',
                          '100 000 opérations/mois',
                          'Support prioritaire',
                          'Exports avancés (CSV)',
                          'Historique illimité',
                          'Scanner codes-barres',
                          'Alertes personnalisées',
                        ],
                        true,
                        false,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
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
      constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 380),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isPopular
            ? colorScheme.primaryContainer.withValues(alpha: 0.08)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.2),
          width: isPopular ? 2 : 1,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ]
            : [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'POPULAIRE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          if (isPopular) const SizedBox(height: 20),
          Text(
            name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    period,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
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
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: isPopular ? 2 : 0,
                side: isPopular ? null : BorderSide(color: colorScheme.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Commencer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 15,
                          color: colorScheme.onSurface,
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

  Widget _buildComparisonSection(ColorScheme colorScheme, bool isMobile) {
    final features = [
      {'name': 'Utilisateurs', 'free': '3', 'pro': '20'},
      {'name': 'Produits', 'free': '200', 'pro': '10 000'},
      {'name': 'Opérations/mois', 'free': '1 000', 'pro': '100 000'},
      {'name': 'Support', 'free': 'Communautaire', 'pro': 'Prioritaire'},
      {'name': 'Exports CSV', 'free': 'Basique', 'pro': 'Avancés'},
      {'name': 'Scanner codes-barres', 'free': '—', 'pro': '✓'},
      {'name': 'Alertes personnalisées', 'free': '—', 'pro': '✓'},
      {'name': 'Historique', 'free': '30 jours', 'pro': 'Illimité'},
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
            'Comparaison détaillée',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 32 : 42,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 48),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                ),
                columns: [
                  DataColumn(
                    label: Text(
                      'Fonctionnalité',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Free',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Pro',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
                rows: features.map((f) {
                  return DataRow(
                    cells: [
                      DataCell(Text(f['name']!, style: TextStyle(fontSize: 14))),
                      DataCell(Text(f['free']!, style: TextStyle(fontSize: 14))),
                      DataCell(
                        Text(
                          f['pro']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(ColorScheme colorScheme, bool isMobile) {
    final faqs = [
      {
        'q': 'Puis-je changer de plan à tout moment ?',
        'a':
            'Oui, vous pouvez passer du plan Free au plan Pro (ou inversement) à tout moment depuis votre espace de facturation. Le changement est immédiat.',
      },
      {
        'q': 'Que se passe-t-il si je dépasse mes limites ?',
        'a':
            'Nous vous enverrons une notification par email. Vous pourrez alors passer au plan supérieur ou attendre le mois suivant (plan Free).',
      },
      {
        'q': 'Y a-t-il des frais cachés ?',
        'a':
            'Non, aucun frais caché. Le prix affiché est le prix final. Pas de frais d\'installation, de formation ou de mise à jour.',
      },
      {
        'q': 'Comment fonctionne la facturation annuelle ?',
        'a':
            'En choisissant la facturation annuelle, vous économisez 20% sur le plan Pro. Vous êtes facturé une fois par an et pouvez annuler à tout moment.',
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
            'Questions fréquentes',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 32 : 42,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 48),
          ...faqs.map((faq) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(
                      faq['q']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Text(
                          faq['a']!,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
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
            colorScheme.primaryContainer.withValues(alpha: 0.2),
            colorScheme.secondaryContainer.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Commencez gratuitement dès maintenant',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 32 : 42,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune carte bancaire requise · Essai gratuit 14 jours',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                  'Créer mon compte',
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
                      onPressed: () => Navigator.pushNamed(context, '/features'),
                      child: const Text('Fonctionnalités'),
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

