Standards d’ingénierie (référence Flutter Docs)

Architecture et état
- State management: `provider` (actuel), éviter la logique lourde dans les widgets; préférer services dédiés.
- Immutabilité: modèles en `final`, `copyWith`, `fromMap`/`toMap` propres.
- Séparation couches: UI (widgets) / logique (services, providers) / données (Firestore).

Pratiques Flutter
- Initialisation: `WidgetsFlutterBinding.ensureInitialized()` + Firebase init dans `main()`.
- Navigation: routes nommées ou `MaterialPageRoute` avec types sûrs.
- Performance: `const` partout possible, éviter rebuilds inutiles, `listen: false` par défaut.
- Ressources: `TextEditingController` et Streams correctement disposés.

Qualité et DX
- Lints: `analysis_options.yaml` (flutter_lints) + règles renforcées.
- CI: analyse + format check sur PRs.
- Tests: unités pour services, widget tests pour écrans clés.

SaaS multi-tenant
- `tenantId` obligatoire, filtres Firestore par tenant, règles d’accès documentées.
- Facturation: entitlements en config (YAML), enforcement côté UI et services.

Références
- Flutter: docs flutter.dev (guides, cookbook, best practices).
- Firebase: Firestore rules, sécurité, performance.
- Stripe: Webhooks et Customer Portal.


