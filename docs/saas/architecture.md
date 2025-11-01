Architecture SaaS (Firebase + Cloudflare + Stripe)

Multi-tenant:
- `tenantId` sur chaque document Firestore (products, users, operations).
- Collections: tenants/{tenantId}, memberships/{docId} {userId, tenantId, role}, usage/{tenantId}.

Auth:
- Connexion par code existante, rattacher un `tenantId`.

Facturation (Stripe):
- Checkout/Portal, webhook (Cloudflare Worker) qui met à jour plan/entitlements.

Enforcement:
- UI: masquage/CTA si quota dépassé.
- Firestore rules: isolation inter-tenant (à déployer plus tard).

Déploiement sans frais fixes:
- App Flutter, Workers gratuits, Pages gratuites.

Étapes:
1) Ajouter `tenantId` app + données.
2) Écran Plans & Facturation + entitlements.
3) Webhook Stripe (test) + secrets.
4) Règles Firestore + migration douce.


