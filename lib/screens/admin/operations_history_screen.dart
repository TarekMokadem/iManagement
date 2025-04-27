import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../models/operation.dart';
import '../../services/operation_service.dart';

class OperationsHistoryScreen extends StatefulWidget {
  const OperationsHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OperationsHistoryScreen> createState() => _OperationsHistoryScreenState();
}

class _OperationsHistoryScreenState extends State<OperationsHistoryScreen> {
  final OperationService _operationService = OperationService();
  OperationType? _selectedType;
  String _searchQuery = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR');
  }

  Stream<List<Operation>> _getFilteredOperations() {
    if (_selectedDate != null) {
      return _operationService.getOperationsByDate(_selectedDate!);
    } else if (_selectedType != null) {
      return _operationService.getOperationsByType(_selectedType!);
    }
    return _operationService.getAllOperations();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des opérations'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt),
            onSelected: (value) {
              switch (value) {
                case 'date':
                  _selectDate();
                  break;
                case 'type':
                  _showFilterDialog();
                  break;
                case 'clear':
                  setState(() {
                    _selectedDate = null;
                    _selectedType = null;
                    _searchQuery = '';
                  });
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text('Filtrer par date'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'type',
                child: Row(
                  children: [
                    Icon(Icons.filter_list),
                    SizedBox(width: 8),
                    Text('Filtrer par type'),
                  ],
                ),
              ),
              if (_selectedDate != null || _selectedType != null)
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all),
                      SizedBox(width: 8),
                      Text('Effacer les filtres'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Rechercher',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_selectedType != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Chip(
                            label: Text(
                              'Type: ${_selectedType == OperationType.entree ? "Entrée" : "Sortie"}',
                            ),
                            onDeleted: () {
                              setState(() {
                                _selectedType = null;
                              });
                            },
                          ),
                        ),
                      if (_selectedDate != null)
                        Chip(
                          label: Text(
                            'Date: ${DateFormat.yMMMMd('fr_FR').format(_selectedDate!)}',
                          ),
                          onDeleted: () {
                            setState(() {
                              _selectedDate = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Operation>>(
              stream: _getFilteredOperations(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final operations = snapshot.data!.where((operation) {
                  if (_searchQuery.isEmpty) return true;
                  return operation.productName.toLowerCase().contains(_searchQuery) ||
                         operation.userName.toLowerCase().contains(_searchQuery);
                }).toList();

                if (operations.isEmpty) {
                  return const Center(
                    child: Text('Aucune opération trouvée'),
                  );
                }

                return ListView.builder(
                  itemCount: operations.length,
                  itemBuilder: (context, index) {
                    final operation = operations[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: operation.type == OperationType.entree
                              ? Colors.green
                              : Colors.red,
                          child: Icon(
                            operation.type == OperationType.entree
                                ? Icons.add
                                : Icons.remove,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          operation.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              operation.type == OperationType.entree
                                  ? 'Entrée: +${operation.quantity}'
                                  : 'Sortie: -${operation.quantity}',
                              style: TextStyle(
                                color: operation.type == OperationType.entree
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Par: ${operation.userName}'),
                            Text(
                              'Le: ${DateFormat.yMMMMd('fr_FR').add_Hm().format(operation.dateTime)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filtrer par type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Toutes les opérations'),
                leading: Radio<OperationType?>(
                  value: null,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                      Navigator.pop(context);
                    });
                  },
                ),
              ),
              ListTile(
                title: const Text('Entrées'),
                leading: Radio<OperationType?>(
                  value: OperationType.entree,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                      Navigator.pop(context);
                    });
                  },
                ),
              ),
              ListTile(
                title: const Text('Sorties'),
                leading: Radio<OperationType?>(
                  value: OperationType.sortie,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                      Navigator.pop(context);
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 