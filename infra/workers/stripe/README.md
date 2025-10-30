Squelette Cloudflare Worker (Stripe Webhook)

Endpoints:
- POST /stripe/webhook: reçoit événements Stripe, vérifie la signature, met à jour Firestore (plan, statut, entitlements).

Secrets à définir (wrangler):
- STRIPE_WEBHOOK_SECRET
- GCP_SERVICE_ACCOUNT (JSON)

À venir: `worker.js` minimal et wrangler.toml d'exemple.


