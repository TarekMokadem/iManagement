import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../widgets/action_button.dart';

class UserManagementScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserManagementScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Utilisateurs'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (String value) {
              setState(() {
                if (_sortBy == value) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = true;
                }
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'name',
                child: Text('Trier par nom'),
              ),
              const PopupMenuItem<String>(
                value: 'code',
                child: Text('Trier par code'),
              ),
              const PopupMenuItem<String>(
                value: 'role',
                child: Text('Trier par rôle'),
              ),
            ],
          ),
          ActionButton(
            icon: Icons.add,
            onPressed: () => _showAddUserDialog(context),
            tooltip: 'Ajouter un utilisateur',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher un utilisateur',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? ActionButton(
                        icon: Icons.clear,
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                        tooltip: 'Effacer la recherche',
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: _userService.getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur de chargement des utilisateurs\n${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Chargement des utilisateurs...'),
                      ],
                    ),
                  );
                }

                final users = snapshot.data!;
                final filteredUsers = users.where((user) {
                  return user.name.toLowerCase().contains(_searchQuery) ||
                      user.code.toLowerCase().contains(_searchQuery);
                }).toList();

                filteredUsers.sort((a, b) {
                  int result;
                  switch (_sortBy) {
                    case 'name':
                      result = a.name.compareTo(b.name);
                      break;
                    case 'code':
                      result = a.code.compareTo(b.code);
                      break;
                    case 'role':
                      result = (a.isAdmin ? 1 : 0).compareTo(b.isAdmin ? 1 : 0);
                      break;
                    default:
                      result = 0;
                  }
                  return _sortAscending ? result : -result;
                });

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: ListTile(
                        title: Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Code: ${user.code}'),
                            Text(
                              'Rôle: ${user.isAdmin ? 'Administrateur' : 'Employé'}',
                              style: TextStyle(
                                color: user.isAdmin ? Colors.blue : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ActionButton(
                              icon: Icons.edit,
                              onPressed: () => _showEditUserDialog(context, user),
                              tooltip: 'Modifier',
                              isSecondary: true,
                            ),
                            ActionButton(
                              icon: Icons.delete,
                              onPressed: () => _showDeleteConfirmationDialog(context, user),
                              tooltip: 'Supprimer',
                              color: Colors.red,
                              isSecondary: true,
                            ),
                          ],
                        ),
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

  Future<void> _showAddUserDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    bool isAdmin = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajouter un utilisateur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Code'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Administrateur'),
                    const Spacer(),
                    Switch(
                      value: isAdmin,
                      onChanged: (value) {
                        setState(() {
                          isAdmin = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    codeController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez remplir tous les champs'),
                    ),
                  );
                  return;
                }

                final isCodeAvailable = await _userService.isCodeAvailable(codeController.text.trim());
                if (!isCodeAvailable) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ce code est déjà utilisé'),
                    ),
                  );
                  return;
                }

                final newUser = AppUser(
                  id: '',
                  name: nameController.text.trim(),
                  code: codeController.text.trim(),
                  isAdmin: isAdmin,
                );

                await _userService.addUser(newUser);
                Navigator.pop(context);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditUserDialog(BuildContext context, AppUser user) async {
    final nameController = TextEditingController(text: user.name);
    final codeController = TextEditingController(text: user.code);
    bool isAdmin = user.isAdmin;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier un utilisateur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Code'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Administrateur'),
                    const Spacer(),
                    Switch(
                      value: isAdmin,
                      onChanged: (value) {
                        setState(() {
                          isAdmin = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    codeController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez remplir tous les champs'),
                    ),
                  );
                  return;
                }

                if (codeController.text.trim() != user.code) {
                  final isCodeAvailable = await _userService.isCodeAvailable(codeController.text.trim());
                  if (!isCodeAvailable) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ce code est déjà utilisé'),
                      ),
                    );
                    return;
                  }
                }

                final updatedUser = user.copyWith(
                  name: nameController.text.trim(),
                  code: codeController.text.trim(),
                  isAdmin: isAdmin,
                );

                await _userService.updateUser(user.id, updatedUser);
                Navigator.pop(context);
              },
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, AppUser user) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'utilisateur ${user.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await _userService.deleteUser(user.id);
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
} 