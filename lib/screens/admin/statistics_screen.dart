import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/operation_service.dart';
import '../../models/operation.dart';

class StatisticsScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const StatisticsScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final OperationService _operationService = OperationService();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 24),
            _buildWeeklyConsumptionChart(),
            const SizedBox(height: 24),
            _buildTopProductsChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Période',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _periods.map((period) {
                return ChoiceChip(
                  label: Text(_getPeriodLabel(period)),
                  selected: _selectedPeriod == period,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPeriod = period;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyConsumptionChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consommation par Jour de la Semaine',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: StreamBuilder<List<Operation>>(
                stream: _operationService.getAllOperations(),
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
                    if (operation.type == OperationType.sortie) {
                      final day = operation.dateTime.weekday;
                      dailyOperations[day - 1].add(operation);
                    }
                  }

                  // Calculer le nombre total d'opérations par jour
                  final dailyTotals = dailyOperations.map((ops) => ops.length).toList();

                  // Calculer les produits les plus consommés par jour
                  final dailyTopProducts = List.generate(7, (index) {
                    final productCounts = <String, int>{};
                    for (var operation in dailyOperations[index]) {
                      productCounts[operation.productName] = 
                          (productCounts[operation.productName] ?? 0) + 1;
                    }
                    return productCounts.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                  });

                  if (dailyTotals.every((total) => total == 0)) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune consommation enregistrée\npour la période sélectionnée',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
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
                                    '${rod.toY.toInt()} sorties\n\n'
                                    'Top 3 produits:\n$topProductsText',
                                    const TextStyle(color: Colors.white),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
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
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(7, (index) {
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: dailyTotals[index].toDouble(),
                                    color: Colors.orange,
                                    width: 20,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(6),
                                      topRight: Radius.circular(6),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Top 3 des produits les plus consommés par jour',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(7, (index) {
                            final topProducts = dailyTopProducts[index];
                            return Expanded(
                              child: Card(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getDayName(index + 1),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...topProducts.take(3).map((entry) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                entry.key,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              '${entry.value}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
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

  Widget _buildTopProductsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 5 des Produits les Plus Mouvementés',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Operation>>(
              stream: _operationService.getAllOperations(),
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
                      (productMovements[operation.productName] ?? 0) + 1;
                }

                final sortedProducts = productMovements.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                if (sortedProducts.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun mouvement pour la période sélectionnée',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedProducts.length > 5 ? 5 : sortedProducts.length,
                  itemBuilder: (context, index) {
                    final entry = sortedProducts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(entry.key),
                      trailing: Text(
                        '${entry.value} mouvements',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
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