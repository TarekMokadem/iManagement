import 'package:flutter/material.dart';

/// Layout wrapper pour toutes les pages publiques (landing, features, pricing, legal, auth)
/// Fournit une navbar cohérente avec navigation fluide
class PublicLayout extends StatelessWidget {
  final Widget child;
  final bool showBackButton;

  const PublicLayout({
    super.key,
    required this.child,
    this.showBackButton = false,
  });

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
            _buildAppBar(context, colorScheme, isMobile),
            SliverToBoxAdapter(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme, bool isMobile) {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
      leadingWidth: showBackButton ? 56 : 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      automaticallyImplyLeading: false,
      title: GestureDetector(
        onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
        ),
      ),
      actions: [
        if (!isMobile) ...[
          _NavButton(
            label: 'Accueil',
            onPressed: () => _navigateTo(context, '/'),
          ),
          _NavButton(
            label: 'Fonctionnalités',
            onPressed: () => _navigateTo(context, '/features'),
          ),
          _NavButton(
            label: 'Tarifs',
            onPressed: () => _navigateTo(context, '/pricing'),
          ),
          Builder(
            builder: (btnContext) => _NavButton(
              label: 'Connexion',
              onPressed: () => _showLoginMenu(btnContext),
            ),
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
        if (isMobile)
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {
              switch (value) {
                case 'features':
                  Navigator.pushNamed(context, '/features');
                  break;
                case 'pricing':
                  Navigator.pushNamed(context, '/pricing');
                  break;
                case 'tenant-login':
                  Navigator.pushNamed(context, '/tenant-login');
                  break;
                case 'user-login':
                  Navigator.pushNamed(context, '/login');
                  break;
                case 'legal':
                  Navigator.pushNamed(context, '/legal');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'features', child: Text('Fonctionnalités')),
              const PopupMenuItem(value: 'pricing', child: Text('Tarifs')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'tenant-login', child: Text('Espace client')),
              const PopupMenuItem(value: 'user-login', child: Text('Connexion utilisateur')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'legal', child: Text('Mentions légales')),
            ],
          ),
      ],
    );
  }

  void _navigateTo(BuildContext context, String route) {
    // Si on est déjà sur la route, ne rien faire
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.pushNamed(context, route);
  }

  void _showLoginMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final button = context.findRenderObject() as RenderBox?;
    if (button == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(button.size.bottomLeft(Offset.zero), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'tenant',
          child: Row(
            children: [
              Icon(Icons.business, size: 20, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Espace client', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('Gestion de compte', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'user',
          child: Row(
            children: [
              Icon(Icons.person, size: 20, color: colorScheme.primary),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Utilisateur', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('Application de stock', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (!context.mounted) return;
      if (value == 'tenant') {
        Navigator.pushNamed(context, '/tenant-login');
      } else if (value == 'user') {
        Navigator.pushNamed(context, '/login');
      }
    });
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _NavButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}

