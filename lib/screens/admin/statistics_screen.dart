import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/operation.dart';
import '../../providers/tenant_provider.dart';
import '../../repositories/operations_repository.dart';

class StatisticsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const StatisticsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = '7j';
  final List<String> _periods = ['7j', '30j', '90j', '1an'];

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case '7j':
        return now.subtract(const Duration(days: 7));
      case '30j':
        return now.subtract(const Duration(days: 30));
      case '90j':
        return now.subtract(const Duration(days: 90));
      case '1an':
        return DateTime(now.year - 1, now.month, now.day);
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case '7j':
        return '7 derniers jours';
      case '30j':
        return '30 derniers jours';
      case '90j':
        return '90 derniers jours';
      case '1an':
        return '1 an';
      default:
        return period;
    }
  }

  String _getDayName(int day) {
    switch (day) {
      case 1:
        return 'Lun';
      case 2:
        return 'Mar';
      case 3:
        return 'Mer';
      case 4:
        return 'Jeu';
      case 5:
        return 'Ven';
      case 6:
        return 'Sam';
      case 7:
        return 'Dim';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Statistiques',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPeriodSelector(colorScheme),
            const SizedBox(height: 24),
            _buildWeeklyConsumptionChart(colorScheme),
            const SizedBox(height: 24),
            _buildTopProductsChart(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(ColorScheme colorScheme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.3),
              colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Période d\'analyse',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _periods.map((period) {
                final isSelected = _selectedPeriod == period;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: ChoiceChip(
                    label: Text(
                      _getPeriodLabel(period),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: colorScheme.primary,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    labelStyle: TextStyle(
                      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                    ),
                    elevation: isSelected ? 4 : 0,
                    pressElevation: 6,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPeriod = period;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyConsumptionChart(ColorScheme colorScheme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              colorScheme.secondaryContainer.withValues(alpha: 0.2),
              colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: colorScheme.secondary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Mouvements par Jour',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 400,
              child: StreamBuilder<List<Operation>>(
                stream: Provider.of<OperationsRepository>(context, listen: false)
                    .watchAll(
                  tenantId: Provider.of<TenantProvider>(context, listen: false).tenantId ?? 'default',
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final startDate = _getStartDate();
                  final operations = snapshot.data!
                      .where((op) => op.dateTime.isAfter(startDate))
                      .toList();

                  // Regrouper les opérations par jour de la semaine
                  final dailyOperations = List.generate(7, (index) => <Operation>[]);
                  for (var operation in operations) {
                    final day = operation.dateTime.weekday;
                    dailyOperations[day - 1].add(operation);
                  }

                  // Calculer la quantité totale de mouvements par jour
                  final dailyTotals = dailyOperations
                      .map((ops) => ops.fold<int>(0, (sum, op) => sum + op.quantity))
                      .toList();

                  // Calculer les produits les plus mouvementés par jour
                  final dailyTopProducts = List.generate(7, (index) {
                    final productCounts = <String, int>{};
                    for (var operation in dailyOperations[index]) {
                      productCounts[operation.productName] = 
                          (productCounts[operation.productName] ?? 0) + operation.quantity;
                    }
                    return productCounts.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                  });

                  if (dailyTotals.every((total) => total == 0)) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun mouvement enregistré',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'pour la période sélectionnée',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: dailyTotals.reduce((a, b) => a > b ? a : b).toDouble(),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final topProducts = dailyTopProducts[groupIndex];
                                  final topProductsText = topProducts.take(3).map((e) => 
                                    '${e.key}: ${e.value}').join('\n');
                                  return BarTooltipItem(
                                    '${_getDayName(groupIndex + 1)}\n'
                                    '${rod.toY.toInt()} mouvements\n\n'
                                    'Top 3 produits:\n$topProductsText',
                                    const TextStyle(color: Colors.white),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value >= 0 && value < 7) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          _getDayName(value.toInt() + 1),
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(7, (index) {
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: dailyTotals[index].toDouble(),
                                    gradient: LinearGradient(
                                      colors: [
                                        colorScheme.primary,
                                        colorScheme.secondary,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    width: 24,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Top 3 produits par jour',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 180,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: 7,
                                separatorBuilder: (context, index) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  final topProducts = dailyTopProducts[index];
                                  return Container(
                                    width: 200,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.outline.withValues(alpha: 0.2),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.shadow.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _getDayName(index + 1),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: colorScheme.onPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Expanded(
                                          child: topProducts.isEmpty
                                              ? Center(
                                                  child: Text(
                                                    'Aucun mouvement',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: colorScheme.outline,
                                                    ),
                                                  ),
                                                )
                                              : ListView.separated(
                                                  itemCount: topProducts.length > 3 ? 3 : topProducts.length,
                                                  separatorBuilder: (context, idx) => const Divider(height: 12),
                                                  itemBuilder: (context, idx) {
                                                    final entry = topProducts[idx];
                                                    return Row(
                                                      children: [
                                                        Container(
                                                          width: 24,
                                                          height: 24,
                                                          decoration: BoxDecoration(
                                                            color: idx == 0
                                                                ? Colors.amber
                                                                : idx == 1
                                                                    ? Colors.grey.shade400
                                                                    : Colors.brown.shade300,
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              '${idx + 1}',
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                entry.key,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: const TextStyle(
                                                                  fontSize: 13,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                              Text(
                                                                '${entry.value} unités',
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: colorScheme.outline,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsChart(ColorScheme colorScheme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              colorScheme.tertiaryContainer.withValues(alpha: 0.2),
              colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: colorScheme.tertiary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Top 5 Produits',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<Operation>>(
              stream: Provider.of<OperationsRepository>(context, listen: false)
                  .watchAll(
                tenantId: Provider.of<TenantProvider>(context, listen: false).tenantId ?? 'default',
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final startDate = _getStartDate();
                final operations = snapshot.data!
                    .where((op) => op.dateTime.isAfter(startDate))
                    .toList();

                final productMovements = <String, int>{};

                for (var operation in operations) {
                  productMovements[operation.productName] = 
                      (productMovements[operation.productName] ?? 0) + operation.quantity;
                }

                final sortedProducts = productMovements.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                if (sortedProducts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun mouvement',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'pour la période sélectionnée',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedProducts.length > 5 ? 5 : sortedProducts.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  itemBuilder: (context, index) {
                    final entry = sortedProducts[index];
                    final medalColors = [
                      Colors.amber,
                      Colors.grey.shade400,
                      Colors.brown.shade300,
                      colorScheme.primary.withValues(alpha: 0.7),
                      colorScheme.primary.withValues(alpha: 0.5),
                    ];
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: medalColors[index],
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: medalColors[index].withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${entry.value} unités mouvementées',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${entry.value}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 