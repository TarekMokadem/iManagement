import 'package:flutter/material.dart';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen>
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SelectionArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(colorScheme),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildHeroSection(colorScheme, isMobile),
                    _buildContent(colorScheme, isMobile),
                    _buildFooter(colorScheme, isMobile),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Icon(Icons.inventory_2, color: colorScheme.primary, size: 24),
          const SizedBox(width: 8),
          Text(
            'iManagement',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(ColorScheme colorScheme, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: isMobile ? 60 : 80,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.1),
            colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.gavel_outlined,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Mentions légales',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 36 : 48,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Dernière mise à jour : 14 décembre 2024',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme, bool isMobile) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: isMobile ? 40 : 60,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            colorScheme,
            '1. Éditeur du site',
            '''
Le site iManagement est édité par iManagement SAS, société par actions simplifiée au capital de 10 000 euros, immatriculée au RCS de Paris sous le numéro 123 456 789.

Siège social : 123 rue de la Tech, 75001 Paris, France
Email : contact@imanagement.fr
Téléphone : +33 1 23 45 67 89

Directeur de la publication : [Nom du directeur]
''',
          ),
          _buildSection(
            colorScheme,
            '2. Hébergement',
            '''
Le site est hébergé par :

Google Cloud Platform (Firebase)
Google LLC
1600 Amphitheatre Parkway
Mountain View, CA 94043, USA

Les données sont hébergées dans des centres de données sécurisés situés en Europe (région europe-west1).
''',
          ),
          _buildSection(
            colorScheme,
            '3. Propriété intellectuelle',
            '''
L'ensemble des contenus présents sur le site iManagement (textes, images, graphismes, logo, icônes, etc.) sont la propriété exclusive de iManagement SAS, à l'exception des marques, logos ou contenus appartenant à d'autres sociétés partenaires ou auteurs.

Toute reproduction, distribution, modification, adaptation, retransmission ou publication de ces différents éléments est strictement interdite sans l'accord exprès par écrit de iManagement SAS.
''',
          ),
          _buildSection(
            colorScheme,
            '4. Protection des données personnelles',
            '''
Conformément au Règlement Général sur la Protection des Données (RGPD) et à la loi Informatique et Libertés, vous disposez d'un droit d'accès, de rectification, de suppression et d'opposition aux données personnelles vous concernant.

Pour exercer ces droits, vous pouvez nous contacter à l'adresse : privacy@imanagement.fr

Responsable du traitement : iManagement SAS
Délégué à la protection des données : dpo@imanagement.fr

Les données collectées sont :
• Données d'inscription (nom, email)
• Données d'utilisation du service (produits, opérations)
• Données de facturation (pour les plans payants)

Ces données sont conservées pour la durée nécessaire à la fourniture du service et sont hébergées en Europe.
''',
          ),
          _buildSection(
            colorScheme,
            '5. Cookies',
            '''
Le site iManagement utilise des cookies strictement nécessaires au fonctionnement du service :

• Cookies d'authentification : pour maintenir votre session
• Cookies de préférences : pour sauvegarder vos paramètres

Aucun cookie de tracking ou publicitaire n'est utilisé. Vous pouvez désactiver les cookies dans les paramètres de votre navigateur, mais cela peut affecter le fonctionnement du service.
''',
          ),
          _buildSection(
            colorScheme,
            '6. Conditions d\'utilisation',
            '''
En utilisant ce site, vous acceptez les présentes mentions légales et nos conditions générales d'utilisation.

iManagement SAS met tout en œuvre pour offrir un service de qualité. Toutefois, nous ne pouvons garantir la disponibilité continue du service et déclinons toute responsabilité en cas d'interruption temporaire.

Les utilisateurs s'engagent à :
• Ne pas utiliser le service à des fins illégales
• Ne pas tenter de compromettre la sécurité du service
• Respecter les droits de propriété intellectuelle
• Maintenir la confidentialité de leurs identifiants
''',
          ),
          _buildSection(
            colorScheme,
            '7. Limitation de responsabilité',
            '''
iManagement SAS ne saurait être tenue responsable :

• Des dommages directs ou indirects résultant de l'utilisation du service
• De la perte de données due à une mauvaise utilisation ou à un cas de force majeure
• Des interruptions de service pour maintenance ou mises à jour

Les utilisateurs sont responsables de la sauvegarde régulière de leurs données. Nous recommandons d'utiliser la fonctionnalité d'export CSV disponible dans le service.
''',
          ),
          _buildSection(
            colorScheme,
            '8. Droit applicable',
            '''
Les présentes mentions légales sont régies par le droit français. En cas de litige, et après tentative de résolution amiable, les tribunaux français seront seuls compétents.
''',
          ),
          _buildSection(
            colorScheme,
            '9. Contact',
            '''
Pour toute question concernant ces mentions légales, vous pouvez nous contacter :

Par email : legal@imanagement.fr
Par courrier : iManagement SAS, 123 rue de la Tech, 75001 Paris, France
Par téléphone : +33 1 23 45 67 89 (du lundi au vendredi, 9h-18h)
''',
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.primary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Besoin d\'aide ?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Notre équipe est à votre disposition pour répondre à vos questions. N\'hésitez pas à nous contacter.',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.email_outlined, size: 18),
                  label: const Text(
                    'Nous contacter',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(ColorScheme colorScheme, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content.trim(),
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.7,
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

