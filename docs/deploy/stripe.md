Configurer Stripe (test, sans frais fixes)

1) Créez un compte Stripe et activez le mode test.
2) Créez un Produit et un Price (mensuel) → récupérez `price_...`.
3) Créez les clés API test: `sk_test_...`.
4) Webhook:
   - URL: `https://<votre-worker>.workers.dev/stripe/webhook`
   - Événements: `checkout.session.completed`, `customer.subscription.*`.
   - Récupérez le `whsec_...`.

Cloudflare Worker (wrangler)
- Secrets à définir dans le dashboard/env:
  - `STRIPE_SECRET_KEY = sk_test_...`
  - `STRIPE_WEBHOOK_SECRET = whsec_...`
  - `FIREBASE_PROJECT_ID = ...` (pour mises à jour futures dans Firestore)

Créer une session Checkout (côté client)
- Appeler `POST /checkout/session` du Worker avec JSON:
```json
{ "priceId": "price_xxx", "successUrl": "https://app.pages.dev/success", "cancelUrl": "https://app.pages.dev/cancel" }
```
La réponse contient l’objet Session; rediriger l’utilisateur vers `url` si vous utilisez la Redirect Session, ou utilisez Stripe.js sur le web (plus tard).

Sécurité
- Implémenter la vérification de signature du webhook (HMAC-SHA256) avant d’écrire en base (TODO dans worker).


