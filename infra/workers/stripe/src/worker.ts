export interface Env {
  STRIPE_SECRET_KEY: string;
  STRIPE_WEBHOOK_SECRET: string; // TODO: implémenter la vérification de signature
  FIREBASE_PROJECT_ID: string;   // TODO: utilisation REST Firestore
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === 'POST' && url.pathname === '/stripe/webhook') {
      // TODO: vérifier la signature Stripe (t=..., v1=...) via HMAC-SHA256
      const payload = await request.text();
      console.log('Stripe webhook reçu (taille):', payload.length);

      // TODO: mettre à jour Firestore (plan/entitlements) via REST API
      return new Response('ok', { status: 200 });
    }

    if (request.method === 'POST' && url.pathname === '/checkout/session') {
      // Crée une session Checkout Stripe minimaliste
      const body: any = await request.json().catch(() => ({}));
      const priceId = body.priceId;
      const successUrl = body.successUrl;
      const cancelUrl = body.cancelUrl;

      if (!priceId || !successUrl || !cancelUrl) {
        return new Response('Paramètres manquants', { status: 400 });
      }

      const resp = await fetch('https://api.stripe.com/v1/checkout/sessions', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${env.STRIPE_SECRET_KEY}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          mode: 'subscription',
          'line_items[0][price]': priceId,
          'line_items[0][quantity]': '1',
          success_url: successUrl,
          cancel_url: cancelUrl,
        }),
      });

      if (!resp.ok) {
        const txt = await resp.text();
        console.error('Stripe error:', txt);
        return new Response('Stripe API error', { status: 500 });
      }
      return new Response(await resp.text(), { status: 200, headers: { 'Content-Type': 'application/json' } });
    }

    return new Response('Not found', { status: 404 });
  },
};


