import 'package:flutter/material.dart';
import '../../widgets/action_button.dart';
import 'critical_products_screen.dart';
import 'product_management_screen.dart';
import 'user_management_screen.dart';
import 'operations_history_screen.dart';
import 'statistics_screen.dart';
import 'billing_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const AdminHomeScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        actions: [
          ActionButton(
            icon: Icons.logout,
            onPressed: () {
              // TODO: Implémenter la déconnexion
              Navigator.of(context).pushReplacementNamed('/login');
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Column(
                children: [
                  Text(
                    'Bienvenue, $userName',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Text('Panneau d\'administration'),
                ],
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 600;
                final crossAxisCount = isDesktop ? 3 : 2;
                final cardPadding = isDesktop ? 24.0 : 16.0;
                final iconSize = isDesktop ? 48.0 : 48.0;
                final fontSize = isDesktop ? 20.0 : 16.0;
                final cardHeight = isDesktop ? 200.0 : 160.0;
                final cardWidth = isDesktop ? 300.0 : double.infinity;
                
                return Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: cardPadding,
                    crossAxisSpacing: cardPadding,
                    childAspectRatio: isDesktop ? 1.8 : 1.0,
                    children: [
                      _buildCard(
                        context,
                        icon: Icons.inventory_2,
                        title: 'Gestion des\nproduits',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductManagementScreen(
                                userId: userId,
                                userName: userName,
                              ),
                            ),
                          );
                        },
                        iconSize: iconSize,
                        fontSize: fontSize,
                        cardHeight: cardHeight,
                        cardWidth: cardWidth,
                        isDesktop: isDesktop,
                      ),
                      _buildCard(
                        context,
                        icon: Icons.people,
                        title: 'Gestion des\nutilisateurs',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserManagementScreen(
                                userId: userId,
                                userName: userName,
                              ),
                            ),
                          );
                        },
                        iconSize: iconSize,
                        fontSize: fontSize,
                        cardHeight: cardHeight,
                        cardWidth: cardWidth,
                        isDesktop: isDesktop,
                      ),
                      _buildCard(
                        context,
                        icon: Icons.history,
                        title: 'Historique des\nopérations',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OperationsHistoryScreen(),
                            ),
                          );
                        },
                        iconSize: iconSize,
                        fontSize: fontSize,
                        cardHeight: cardHeight,
                        cardWidth: cardWidth,
                        isDesktop: isDesktop,
                      ),
                      _buildCard(
                        context,
                        icon: Icons.warning,
                        title: 'Produits\ncritiques',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CriticalProductsScreen(
                                userId: userId,
                                userName: userName,
                              ),
                            ),
                          );
                        },
                        iconSize: iconSize,
                        fontSize: fontSize,
                        cardHeight: cardHeight,
                        cardWidth: cardWidth,
                        isDesktop: isDesktop,
                      ),
                      _buildCard(
                        context,
                        icon: Icons.bar_chart,
                        title: 'Statistiques',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StatisticsScreen(
                                userId: userId,
                                userName: userName,
                              ),
                            ),
                          );
                        },
                        iconSize: iconSize,
                        fontSize: fontSize,
                        cardHeight: cardHeight,
                        cardWidth: cardWidth,
                        isDesktop: isDesktop,
                      ),
                      _buildCard(
                        context,
                        icon: Icons.credit_card,
                        title: 'Plans &\nFacturation',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BillingScreen(),
                            ),
                          );
                        },
                        iconSize: iconSize,
                        fontSize: fontSize,
                        cardHeight: cardHeight,
                        cardWidth: cardWidth,
                        isDesktop: isDesktop,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required double iconSize,
    required double fontSize,
    required double cardHeight,
    required double cardWidth,
    required bool isDesktop,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.0),
          splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
          highlightColor: Theme.of(context).primaryColor.withOpacity(0.2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: cardHeight,
            width: cardWidth,
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: isDesktop ? 16.0 : 12.0),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 