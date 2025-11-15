import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';

class OnboardingWizardScreen extends StatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.inventory_2, color: colorScheme.primary, size: 28),
            const SizedBox(width: 8),
            Text(
              'iManagement',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _skipOnboarding,
            child: const Text('Passer'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 24 : 48),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: _buildCurrentStep(colorScheme, isMobile),
                ),
              ),
            ),
          ),
          _buildNavigation(colorScheme, isMobile),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(ColorScheme colorScheme, bool isMobile) {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep(colorScheme, isMobile);
      case 1:
        return _buildProductsStep(colorScheme, isMobile);
      case 2:
        return _buildTeamStep(colorScheme, isMobile);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomeStep(ColorScheme colorScheme, bool isMobile) {
    final session = context.watch<SessionProvider>().session;
    final userName = session?.userName ?? 'Utilisateur';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.celebration,
            size: isMobile ? 80 : 120,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Bienvenue, $userName ! 🎉',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 28 : 36,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Votre compte est prêt ! Configurons ensemble votre espace de travail en 3 étapes rapides.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 48),
        _buildFeatureList(colorScheme, [
          'Ajoutez vos premiers produits',
          'Invitez vos collaborateurs',
          'Découvrez les fonctionnalités clés',
        ]),
      ],
    );
  }

  Widget _buildProductsStep(ColorScheme colorScheme, bool isMobile) {
    return Column(
      children: [
        Icon(
          Icons.inventory_2,
          size: isMobile ? 80 : 100,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 32),
        Text(
          'Ajoutez vos produits',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 28 : 36,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Commencez par ajouter quelques produits à votre inventaire. Vous pourrez les gérer et suivre leurs mouvements en temps réel.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Conseil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Pour chaque produit, renseignez :\n• Nom et emplacement\n• Quantité en stock\n• Seuil critique (pour les alertes)',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/admin');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Ajouter mes premiers produits',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamStep(ColorScheme colorScheme, bool isMobile) {
    return Column(
      children: [
        Icon(
          Icons.people,
          size: isMobile ? 80 : 100,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 32),
        Text(
          'Invitez votre équipe',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 28 : 36,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Collaborez avec vos employés en temps réel. Chacun pourra gérer les stocks selon ses permissions.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 48),
        _buildFeatureList(colorScheme, [
          'Invitez jusqu\'à 3 utilisateurs (plan Free)',
          'Définissez les rôles (Admin / Employé)',
          'Suivez l\'activité de chacun',
        ]),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/admin');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.person_add),
            label: const Text(
              'Inviter des collaborateurs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _skipOnboarding,
          child: const Text('Je le ferai plus tard'),
        ),
      ],
    );
  }

  Widget _buildFeatureList(ColorScheme colorScheme, List<String> features) {
    return Column(
      children: features
          .map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildNavigation(ColorScheme colorScheme, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: () {
                setState(() => _currentStep--);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Précédent'),
            )
          else
            const SizedBox.shrink(),
          Row(
            children: List.generate(
              3,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentStep
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          if (_currentStep < 2)
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _currentStep++);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Suivant'),
            )
          else
            ElevatedButton(
              onPressed: _skipOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: const Text('Terminer'),
            ),
        ],
      ),
    );
  }

  void _skipOnboarding() {
    final session = context.read<SessionProvider>();
    final route = session.isAdmin ? '/admin' : '/employee';
    Navigator.pushReplacementNamed(context, route);
  }
}

