import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/session_provider.dart';
import '../providers/tenant_provider.dart';
import '../repositories/users_repository.dart';
import '../services/session_service.dart';
import '../services/tenant_audit_service.dart';
import '../services/tenant_portal_service.dart';
import '../services/tenant_service.dart';
import '../utils/csv_export.dart';
import '../utils/download/download.dart';
import 'admin/billing_screen.dart';

class TenantDashboardScreen extends StatefulWidget {
  const TenantDashboardScreen({super.key});

  @override
  State<TenantDashboardScreen> createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen> {
  final TenantService _tenantService = TenantService();
  final TenantPortalService _portalService = TenantPortalService();
  final TenantAuditService _auditService = TenantAuditService();
  int _selectedIndex = 0;

  String _buildInvitationsText(List<AppUser> users) {
    const loginUrl = 'https://imanagement.pages.dev/login';
    return users
        .map((u) => 'Nom: ${u.name}\nCode: ${u.code}\nConnexion: $loginUrl\n')
        .join('\n');
  }

  Future<void> _showBulkInviteDialog({
    required BuildContext context,
    required UsersRepository repository,
    required String tenantId,
  }) async {
    final formKey = GlobalKey<FormState>();
    final prefixController = TextEditingController(text: 'Employé');
    final countController = TextEditingController(text: '5');
    final startIndexController = TextEditingController(text: '1');
    var isAdmin = false;
    var isSaving = false;
    int createdCount = 0;

    String generateCode() {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final rnd = Random.secure();
      return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
    }

    Future<String> generateUniqueCode() async {
      for (var i = 0; i < 20; i += 1) {
        final c = generateCode();
        final ok = await repository.isCodeAvailable(c, tenantId: tenantId);
        if (ok) return c;
      }
      throw Exception('Impossible de générer un code unique (trop de collisions)');
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Inviter en masse'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: prefixController,
                  decoration: const InputDecoration(labelText: 'Préfixe des noms (ex: Employé)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: countController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null || n <= 0) return 'Invalide';
                          if (n > 100) return 'Max 100';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: startIndexController,
                        decoration: const InputDecoration(labelText: 'Index départ'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null || n <= 0) return 'Invalide';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: isAdmin,
                  onChanged: isSaving ? null : (v) => setState(() => isAdmin = v),
                  title: const Text('Administrateur'),
                  subtitle: const Text('Donne accès aux écrans admin et à la gestion'),
                ),
                if (isSaving) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: createdCount == 0 ? null : (createdCount / (int.tryParse(countController.text) ?? 1)).clamp(0, 1)),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Créés: $createdCount', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final actorName = context.read<SessionProvider>().session?.userName;
                      final prefix = prefixController.text.trim();
                      final count = int.parse(countController.text.trim());
                      final startIndex = int.parse(startIndexController.text.trim());
                      setState(() {
                        isSaving = true;
                        createdCount = 0;
                      });

                      final created = <AppUser>[];
                      try {
                        for (var i = 0; i < count; i += 1) {
                          final idx = startIndex + i;
                          final name = '$prefix $idx';
                          final code = await generateUniqueCode();
                          final user = AppUser(
                            id: '',
                            name: name,
                            code: code,
                            isAdmin: isAdmin,
                            tenantId: tenantId,
                          );
                          await repository.addUser(user, tenantId: tenantId);
                          // récupérer l'id réel via stream serait coûteux; on garde id vide ici.
                          created.add(user);
                          setState(() => createdCount = created.length);
                        }
                        await _auditService.log(
                          tenantId: tenantId,
                          action: 'users_bulk_created',
                          actorName: actorName,
                          meta: {'count': created.length, 'isAdmin': isAdmin, 'prefix': prefix},
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          await _showBulkInviteResultDialog(context: context, tenantId: tenantId, users: created);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          setState(() => isSaving = false);
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Créer'),
            ),
          ],
        ),
      ),
    );

    prefixController.dispose();
    countController.dispose();
    startIndexController.dispose();
  }

  Future<void> _showBulkInviteResultDialog({
    required BuildContext context,
    required String tenantId,
    required List<AppUser> users,
  }) async {
    final csv = toCsv([
      ['Nom', 'Code', 'Rôle'],
      ...users.map((u) => [u.name, u.code, u.isAdmin ? 'Admin' : 'Employé']),
    ]);
    final invites = _buildInvitationsText(users);

    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Invitations prêtes'),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${users.length} utilisateur(s) créé(s).'),
              const SizedBox(height: 12),
              Text('Astuce: exporte en CSV ou copie le texte d’invitations.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: invites));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitations copiées')));
              }
            },
            child: const Text('Copier invitations'),
          ),
          TextButton(
            onPressed: () {
              try {
                downloadTextFile(
                  filename: 'invites_$tenantId.csv',
                  content: csv,
                  mimeType: 'text/csv',
                );
              } catch (_) {
                // ignore
              }
            },
            child: const Text('Télécharger CSV'),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(c), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final sessionProvider = context.read<SessionProvider>();
    final tenantProvider = context.read<TenantProvider>();
    final navigator = Navigator.of(context);

    await sessionProvider.logout();
    tenantProvider.clearTenant();
    await navigator.pushNamedAndRemoveUntil('/tenant-login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tenantProvider = context.watch<TenantProvider>();
    final session = context.watch<SessionProvider>().session;
    final tenantId = tenantProvider.tenantId;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Espace client'),
        actions: [
          TextButton.icon(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Déconnexion'),
          ),
        ],
      ),
      body: tenantId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<Map<String, dynamic>?>(
              stream: _tenantService.watchTenant(tenantId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tenantData = snapshot.data;

                return SelectionArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 980;
                      final content = _buildBody(
                        context: context,
                        colorScheme: colorScheme,
                        tenantProvider: tenantProvider,
                        session: session,
                        tenantData: tenantData,
                      );

                      if (!isWide) {
                        return Column(
                          children: [
                            Expanded(child: content),
                            _buildBottomNav(colorScheme),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          _buildRail(colorScheme),
                          const VerticalDivider(width: 1),
                          Expanded(child: content),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRail(ColorScheme scheme) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('Aperçu')),
        NavigationRailDestination(icon: Icon(Icons.person_outline), label: Text('Profil')),
        NavigationRailDestination(icon: Icon(Icons.group_outlined), label: Text('Utilisateurs')),
        NavigationRailDestination(icon: Icon(Icons.history), label: Text('Activité')),
        NavigationRailDestination(icon: Icon(Icons.credit_card_outlined), label: Text('Facturation')),
      ],
    );
  }

  Widget _buildBottomNav(ColorScheme scheme) {
    return SafeArea(
      top: false,
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Aperçu'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
          NavigationDestination(icon: Icon(Icons.group_outlined), label: 'Utilisateurs'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Activité'),
          NavigationDestination(icon: Icon(Icons.credit_card_outlined), label: 'Facturation'),
        ],
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required ColorScheme colorScheme,
    required TenantProvider tenantProvider,
    required SessionData? session,
    required Map<String, dynamic>? tenantData,
  }) {
    final padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: SingleChildScrollView(
        key: ValueKey(_selectedIndex),
        padding: padding,
        child: switch (_selectedIndex) {
          0 => _buildOverview(context, colorScheme, tenantProvider, session, tenantData),
          1 => _buildProfilePanel(context, colorScheme, tenantProvider, session, tenantData),
          2 => _buildUsersPanel(context, colorScheme, tenantProvider),
          3 => _buildActivityPanel(context, colorScheme, tenantProvider, session),
          4 => _buildBillingPanel(context, colorScheme, tenantProvider),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _buildOverview(
    BuildContext context,
    ColorScheme colorScheme,
    TenantProvider tenantProvider,
    SessionData? session,
    Map<String, dynamic>? tenantData,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroCard(context, colorScheme, tenantProvider, tenantData),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 900) {
              return Column(
                children: [
                  _buildProfileCard(colorScheme, session, tenantProvider, tenantData),
                  const SizedBox(height: 16),
                  _buildPlanCard(context, colorScheme, tenantProvider),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildProfileCard(colorScheme, session, tenantProvider, tenantData)),
                const SizedBox(width: 16),
                Expanded(child: _buildPlanCard(context, colorScheme, tenantProvider)),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _buildEntitlementsSection(colorScheme, tenantProvider),
      ],
    );
  }

  Widget _sectionHeader(String title, String subtitle, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: scheme.onSurface)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65))),
      ],
    );
  }

  Widget _panelCard(ColorScheme scheme, Widget child) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildProfilePanel(
    BuildContext context,
    ColorScheme scheme,
    TenantProvider tenantProvider,
    SessionData? session,
    Map<String, dynamic>? tenantData,
  ) {
    final tenantId = tenantProvider.tenantId;
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    final currentName = (tenantData?['name'] as String?) ?? '—';
    final currentEmail = (tenantData?['contactEmail'] as String?) ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Profil', 'Gérez les informations de votre organisation', scheme),
        const SizedBox(height: 16),
        _panelCard(
          scheme,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileRow('Organisation', currentName),
              const SizedBox(height: 12),
              _profileRow('Email de contact', currentEmail),
              const SizedBox(height: 12),
              _profileRow('Identifiant tenant', tenantId ?? '—'),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: (tenantId == null || tenantId.isEmpty || firebaseUid == null)
                      ? null
                      : () => _showEditTenantProfileDialog(
                            context: context,
                            tenantId: tenantId,
                            firebaseUid: firebaseUid,
                            currentName: currentName == '—' ? '' : currentName,
                            currentEmail: currentEmail == '—' ? '' : currentEmail,
                          ),
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Note: la modification est réservée aux administrateurs du tenant.',
                style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (session != null)
          _panelCard(
            scheme,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardHeader(Icons.badge_outlined, 'Compte connecté', scheme),
                const SizedBox(height: 12),
                Text(session.userName, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Rôle: administrateur', style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7))),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _showEditTenantProfileDialog({
    required BuildContext context,
    required String tenantId,
    required String firebaseUid,
    required String currentName,
    required String currentEmail,
  }) async {
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController(text: currentEmail);
    final formKey = GlobalKey<FormState>();
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier le profil'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Organisation'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email de contact'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'Champ requis';
                    if (!s.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final actorName = context.read<SessionProvider>().session?.userName;
                      setState(() => isSaving = true);
                      try {
                        await _portalService.updateTenantProfile(
                          tenantId: tenantId,
                          firebaseUid: firebaseUid,
                          name: nameController.text.trim(),
                          contactEmail: emailController.text.trim(),
                        );
                        await _auditService.log(
                          tenantId: tenantId,
                          action: 'tenant_profile_updated',
                          actorName: actorName,
                          meta: const {'source': 'tenant_portal'},
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profil mis à jour')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur mise à jour: $e')),
                          );
                        }
                      } finally {
                        if (dialogContext.mounted) setState(() => isSaving = false);
                      }
                    },
              child: isSaving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    emailController.dispose();
  }

  Widget _buildUsersPanel(BuildContext context, ColorScheme scheme, TenantProvider tenantProvider) {
    final tenantId = tenantProvider.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final repository = Provider.of<UsersRepository>(context, listen: false);
    final searchController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setState) {
        String query = '';
        int visibleCount = 25;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Utilisateurs', 'Invitez et gérez les accès (codes d’accès)', scheme),
            const SizedBox(height: 16),
            _panelCard(
              scheme,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            labelText: 'Rechercher (nom ou code)',
                          ),
                          onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final actorName = context.read<SessionProvider>().session?.userName;
                          final snap = await repository.watchUsers(tenantId: tenantId).first;
                          final users = query.isEmpty
                              ? snap
                              : snap
                                  .where((u) =>
                                      u.name.toLowerCase().contains(query) ||
                                      u.code.toLowerCase().contains(query))
                                  .toList();
                          String fmt(DateTime? dt) => dt?.toIso8601String() ?? '';
                          final csv = toCsv([
                            ['Id', 'Nom', 'Code', 'Rôle', 'Créé le'],
                            ...users.map((u) => [u.id, u.name, u.code, u.isAdmin ? 'Admin' : 'Employé', fmt(u.createdAt)]),
                          ]);
                          final filename = 'utilisateurs_$tenantId.csv';
                          try {
                            downloadTextFile(filename: filename, content: csv, mimeType: 'text/csv');
                          } catch (_) {
                            await Clipboard.setData(ClipboardData(text: csv));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('CSV copié dans le presse-papier')),
                              );
                            }
                          }
                          await _auditService.log(
                            tenantId: tenantId,
                            action: 'users_exported_csv',
                            actorName: actorName,
                            meta: {'count': users.length},
                          );
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Exporter CSV'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showBulkInviteDialog(
                          context: context,
                          repository: repository,
                          tenantId: tenantId,
                        ),
                        icon: const Icon(Icons.group_add_outlined),
                        label: const Text('Inviter en masse'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showAddUserDialog(
                          context: context,
                          repository: repository,
                          tenantId: tenantId,
                        ),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Inviter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<AppUser>>(
                    stream: repository.watchUsers(tenantId: tenantId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Erreur: ${snapshot.error}');
                      }
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final users = snapshot.data!;
                      final filtered = query.isEmpty
                          ? users
                          : users
                              .where((u) =>
                                  u.name.toLowerCase().contains(query) ||
                                  u.code.toLowerCase().contains(query))
                              .toList();

                      if (filtered.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('Aucun utilisateur trouvé.'),
                        );
                      }

                      filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                      final shown = filtered.take(visibleCount).toList();
                      return Column(
                        children: [
                          ...shown.map((u) => _userRow(context, scheme, repository, tenantId, u)),
                          if (shown.length < filtered.length) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.center,
                              child: OutlinedButton(
                                onPressed: () => setState(() => visibleCount += 25),
                                child: Text('Afficher plus (${filtered.length - shown.length})'),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _userRow(
    BuildContext context,
    ColorScheme scheme,
    UsersRepository repository,
    String tenantId,
    AppUser user,
  ) {
    final roleLabel = user.isAdmin ? 'Administrateur' : 'Employé';
    final roleIcon = user.isAdmin ? Icons.admin_panel_settings_outlined : Icons.badge_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primary.withValues(alpha: 0.1),
            child: Icon(roleIcon, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _chip(scheme, Icons.vpn_key_outlined, user.code),
                    _chip(scheme, Icons.shield_outlined, roleLabel),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copier le code',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: user.code));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copié')));
              }
            },
          ),
          IconButton(
            tooltip: 'Copier invitation',
            icon: const Icon(Icons.send_outlined),
            onPressed: () async {
              final actorName = context.read<SessionProvider>().session?.userName;
              const loginUrl = 'https://imanagement.pages.dev/login';
              final msg = 'Voici votre accès iManagement.\n\nCode: ${user.code}\nConnexion: $loginUrl';
              await Clipboard.setData(ClipboardData(text: msg));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation copiée')));
              }
              await _auditService.log(
                tenantId: tenantId,
                action: 'user_invite_copied',
                actorName: actorName,
                meta: {'userId': user.id},
              );
            },
          ),
          IconButton(
            tooltip: 'Régénérer code',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final actorName = context.read<SessionProvider>().session?.userName;
              String generateCode() {
                const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
                final rnd = Random.secure();
                return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
              }

              String? newCode;
              for (var i = 0; i < 10; i += 1) {
                final candidate = generateCode();
                final ok = await repository.isCodeAvailable(candidate, tenantId: tenantId);
                if (ok) {
                  newCode = candidate;
                  break;
                }
              }
              if (newCode == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de générer un code unique')));
                }
                return;
              }
              final updated = user.copyWith(code: newCode, tenantId: tenantId);
              await repository.updateUser(user.id, updated, tenantId: tenantId);
              await _auditService.log(
                tenantId: tenantId,
                action: 'user_code_regenerated',
                actorName: actorName,
                meta: {'userId': user.id},
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code régénéré')));
              }
            },
          ),
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditUserDialog(context, repository, tenantId, user),
          ),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
            onPressed: () => _confirmDeleteUser(context, repository, tenantId, user),
          ),
        ],
      ),
    );
  }

  Widget _chip(ColorScheme scheme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _showAddUserDialog({
    required BuildContext context,
    required UsersRepository repository,
    required String tenantId,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    var isAdmin = false;
    var isSaving = false;

    String generateCode() {
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final rnd = Random.secure();
      return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
    }

    Future<void> autoGenerate() async {
      for (var i = 0; i < 10; i += 1) {
        final c = generateCode();
        final ok = await repository.isCodeAvailable(c, tenantId: tenantId);
        if (ok) {
          codeController.text = c;
          return;
        }
      }
      throw Exception('Impossible de générer un code unique.');
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Inviter un utilisateur'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(labelText: 'Code d’accès'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Code requis' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              try {
                                await autoGenerate();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code généré')));
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                }
                              }
                            },
                      child: const Text('Générer'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: isAdmin,
                  onChanged: isSaving ? null : (v) => setState(() => isAdmin = v),
                  title: const Text('Administrateur'),
                  subtitle: const Text('Peut gérer les utilisateurs et accéder à la partie admin de l’app'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final actorName = context.read<SessionProvider>().session?.userName;
                      setState(() => isSaving = true);
                      try {
                        final trimmedCode = codeController.text.trim();
                        final ok = await repository.isCodeAvailable(trimmedCode, tenantId: tenantId);
                        if (!ok) {
                          throw Exception('Ce code est déjà utilisé');
                        }
                        final user = AppUser(
                          id: '',
                          name: nameController.text.trim(),
                          code: trimmedCode,
                          isAdmin: isAdmin,
                          tenantId: tenantId,
                        );
                        await repository.addUser(user, tenantId: tenantId);
                        await _auditService.log(
                          tenantId: tenantId,
                          action: 'user_created',
                          actorName: actorName,
                          meta: {'name': user.name, 'isAdmin': user.isAdmin},
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilisateur ajouté')));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                        }
                      } finally {
                        if (dialogContext.mounted) setState(() => isSaving = false);
                      }
                    },
              child: isSaving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    codeController.dispose();
  }

  Future<void> _showEditUserDialog(
    BuildContext context,
    UsersRepository repository,
    String tenantId,
    AppUser user,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.name);
    final codeController = TextEditingController(text: user.code);
    var isAdmin = user.isAdmin;
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(labelText: 'Code d’accès'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Code requis' : null,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: isAdmin,
                  onChanged: isSaving ? null : (v) => setState(() => isAdmin = v),
                  title: const Text('Administrateur'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final actorName = context.read<SessionProvider>().session?.userName;
                      setState(() => isSaving = true);
                      try {
                        final updated = user.copyWith(
                          name: nameController.text.trim(),
                          code: codeController.text.trim(),
                          isAdmin: isAdmin,
                          tenantId: tenantId,
                        );
                        await repository.updateUser(user.id, updated, tenantId: tenantId);
                        await _auditService.log(
                          tenantId: tenantId,
                          action: 'user_updated',
                          actorName: actorName,
                          meta: {'userId': user.id},
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilisateur mis à jour')));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                        }
                      } finally {
                        if (dialogContext.mounted) setState(() => isSaving = false);
                      }
                    },
              child: isSaving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    codeController.dispose();
  }

  Future<void> _confirmDeleteUser(
    BuildContext context,
    UsersRepository repository,
    String tenantId,
    AppUser user,
  ) async {
    final actorName = context.read<SessionProvider>().session?.userName;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer ${user.name} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;
    await repository.deleteUser(user.id, tenantId: tenantId);
    await _auditService.log(
      tenantId: tenantId,
      action: 'user_deleted',
      actorName: actorName,
      meta: {'userId': user.id},
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilisateur supprimé')));
    }
  }

  Widget _buildActivityPanel(
    BuildContext context,
    ColorScheme scheme,
    TenantProvider tenantProvider,
    SessionData? session,
  ) {
    final tenantId = tenantProvider.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Activité', 'Historique des actions administratives', scheme),
        const SizedBox(height: 16),
        _panelCard(
          scheme,
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _auditService.watchRecent(tenantId: tenantId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Erreur: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final items = snapshot.data!;
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Aucune activité pour le moment.'),
                );
              }

              return Column(
                children: items.map((e) {
                  final action = (e['action'] as String?) ?? 'action';
                  final actor = (e['actorName'] as String?) ?? '—';
                  final ts = e['createdAt'];
                  DateTime? dt;
                  if (ts is Timestamp) dt = ts.toDate();
                  final when = dt != null ? MaterialLocalizations.of(context).formatShortDate(dt) : '';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.bolt, color: scheme.primary),
                    title: Text(action, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('$actor${when.isNotEmpty ? ' • $when' : ''}'),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBillingPanel(BuildContext context, ColorScheme scheme, TenantProvider tenantProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Facturation', 'Gérez votre plan, vos paiements et vos factures', scheme),
        const SizedBox(height: 16),
        _panelCard(
          scheme,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan actuel: ${tenantProvider.plan.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                tenantProvider.hasPaymentIssue ? 'Paiement à vérifier' : 'Facturation active',
                style: TextStyle(color: tenantProvider.hasPaymentIssue ? Colors.red : scheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.push<void>(context, MaterialPageRoute(builder: (_) => const BillingScreen())),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Ouvrir la facturation'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    ColorScheme colorScheme,
    TenantProvider tenant,
    Map<String, dynamic>? tenantData,
  ) {
    final company = (tenantData?['name'] as String?) ?? 'Votre organisation';
    final createdAt = (tenantData?['createdAt'] as Timestamp?)?.toDate();
    final subtitle = createdAt != null
        ? 'Client depuis le ${MaterialLocalizations.of(context).formatFullDate(createdAt)}'
        : 'Bienvenue dans votre espace client';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.primaryContainer.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.business_rounded, color: colorScheme.onPrimary, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildHeroChip(colorScheme, Icons.workspace_premium_outlined, tenant.plan.toUpperCase()),
              _buildHeroChip(
                colorScheme,
                tenant.hasPaymentIssue ? Icons.warning_amber_rounded : Icons.verified_rounded,
                tenant.hasPaymentIssue ? 'Paiement à vérifier' : 'Facturation active',
                isError: tenant.hasPaymentIssue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(ColorScheme scheme, IconData icon, String label, {bool isError = false}) {
    final bgColor = isError
        ? Colors.red.shade50
        : scheme.primaryContainer.withValues(alpha: 0.5);
    final fgColor = isError ? Colors.red.shade700 : scheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: fgColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fgColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    ColorScheme scheme,
    SessionData? session,
    TenantProvider tenant,
    Map<String, dynamic>? tenantData,
  ) {
    final sanitizedName = (session?.userName ?? '').trim();
    final initials = sanitizedName.isNotEmpty ? sanitizedName[0].toUpperCase() : 'U';
    final billingStatus = tenant.billingStatus;
    final contactEmail = (tenantData?['contactEmail'] as String?) ?? (tenantData?['email'] as String?) ?? 'Non renseigné';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.person_outline, 'Profil', scheme),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: scheme.primary.withValues(alpha: 0.1),
              child: Text(initials, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(session?.userName ?? 'Utilisateur'),
            subtitle: Text(contactEmail),
          ),
          const Divider(),
          _profileRow('Identifiant tenant', session?.tenantId ?? '—'),
          const SizedBox(height: 8),
          _profileRow('Statut facturation', billingStatus),
        ],
      ),
    );
  }

  Widget _cardHeader(IconData icon, String title, ColorScheme scheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: scheme.onSurface),
        ),
      ],
    );
  }

  Widget _profileRow(String label, String value, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ],
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    ColorScheme scheme,
    TenantProvider tenant,
  ) {
    final periodEnd = tenant.billingCurrentPeriodEnd;
    final hasIssue = tenant.hasPaymentIssue;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.workspace_premium_outlined, 'Plan & facturation', scheme),
          const SizedBox(height: 16),
          Text(
            tenant.plan.toUpperCase(),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: scheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            hasIssue
                ? tenant.billingLastPaymentError ?? 'Action requise'
                : 'Facturation active${periodEnd != null ? ' • Renouvellement ${MaterialLocalizations.of(context).formatMediumDate(periodEnd)}' : ''}',
            style: TextStyle(color: hasIssue ? Colors.red : scheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _planPill(Icons.people_alt_outlined, '${tenant.maxUsers ?? '∞'} utilisateurs'),
              _planPill(Icons.inventory_2_outlined, '${tenant.maxProducts ?? '∞'} produits'),
              _planPill(Icons.swap_vert, '${tenant.maxOperationsPerMonth ?? '∞'} opérations/mois'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute(builder: (_) => const BillingScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                  ),
                  child: const Text('Gérer mon abonnement'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/admin'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Accéder à l’application'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _planPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey.shade700),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEntitlementsSection(ColorScheme scheme, TenantProvider tenant) {
    final entitlements = <Map<String, dynamic>>[
      {
        'icon': Icons.analytics_outlined,
        'title': 'Statistiques',
        'description': 'Visibilité sur vos mouvements',
      },
      {
        'icon': Icons.file_present_outlined,
        'title': 'Exports',
        'description': (tenant.entitlements['exports'] == true || tenant.entitlements['exports'] == 'true')
            ? 'Exports avancés activés'
            : 'Inclus dans le plan Pro',
      },
      {
        'icon': Icons.support_agent_outlined,
        'title': 'Support',
        'description': tenant.entitlements['support'] ?? 'Community',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vos avantages',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: scheme.onSurface),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: entitlements.map((item) {
            return Container(
              width: 280,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item['icon'] as IconData, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['description'] as String,
                          style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

