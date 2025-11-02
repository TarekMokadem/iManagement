export interface Env {
  STRIPE_SECRET_KEY: string;
  STRIPE_WEBHOOK_SECRET: string; // utilisé pour vérifier la signature du webhook
  FIREBASE_PROJECT_ID: string;   // TODO: utilisation REST Firestore
}

// --- Helpers cryptographiques pour la vérification de signature Stripe ---
async function hmacSHA256Hex(secret: string, data: string): Promise<string> {
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    enc.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(data));
  const bytes = new Uint8Array(sig);
  return Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('');
}

function parseStripeSignatureHeader(header: string | null): { t: string; v1: string[] } | null {
  if (!header) return null;
  const parts = header.split(',').map(p => p.trim());
  const t = parts.find(p => p.startsWith('t='))?.split('=')[1] ?? '';
  const v1 = parts.filter(p => p.startsWith('v1='))
                  .map(p => p.split('=')[1])
                  .filter(Boolean);
  return t && v1.length ? { t, v1 } : null;
}

async function verifyStripeSignature(env: Env, request: Request, payloadText: string): Promise<boolean> {
  const sigHeader = request.headers.get('Stripe-Signature');
  const parsed = parseStripeSignatureHeader(sigHeader);
  if (!parsed) return false;

  // Stripe signe sur `${t}.${payload}`
  const signedPayload = `${parsed.t}.${payloadText}`;
  const expected = await hmacSHA256Hex(env.STRIPE_WEBHOOK_SECRET, signedPayload);
  return parsed.v1.some(v => v.toLowerCase() === expected.toLowerCase());
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    } as const;

    // Préflight CORS
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: { ...corsHeaders } });
    }

    // Webhook Stripe: vérifie la signature puis traite l'événement minimalement
    if (request.method === 'POST' && url.pathname === '/stripe/webhook') {
      const payloadText = await request.text();
      const valid = await verifyStripeSignature(env, request, payloadText);
      if (!valid) {
        return new Response('Invalid signature', { status: 400, headers: { ...corsHeaders } });
      }

      // NOTE: Ici on pourrait parser l'event et mettre à jour Firestore
      // via l'API REST (plans/entitlements). On renvoie 200 pour Stripe.
      return new Response('ok', { status: 200, headers: { ...corsHeaders } });
    }

    // Création d'une session Checkout (abonnement)
    if (request.method === 'POST' && url.pathname === '/checkout/session') {
      const body: any = await request.json().catch(() => ({}));
      const priceId = body.priceId;
      const successUrl = body.successUrl;
      const cancelUrl = body.cancelUrl;
      const customerId = body.customerId; // optionnel; Stripe créera un customer sinon

      if (!priceId || !successUrl || !cancelUrl) {
        return new Response('Paramètres manquants', { status: 400, headers: { ...corsHeaders } });
      }

      const params = new URLSearchParams({
        mode: 'subscription',
        'line_items[0][price]': priceId,
        'line_items[0][quantity]': '1',
        success_url: successUrl,
        cancel_url: cancelUrl,
      });
      if (customerId) params.set('customer', customerId);

      const resp = await fetch('https://api.stripe.com/v1/checkout/sessions', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${env.STRIPE_SECRET_KEY}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params,
      });
      if (!resp.ok) {
        const txt = await resp.text();
        return new Response(`Stripe API error: ${txt}`, { status: 500, headers: { ...corsHeaders } });
      }
      return new Response(await resp.text(), { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
    }

    // Portail Client: crée une session de portail et renvoie l'URL
    if (request.method === 'POST' && url.pathname === '/billing/portal') {
      const body: any = await request.json().catch(() => ({}));
      const customerId = body.customerId; // requis
      const returnUrl = body.returnUrl;   // recommandé
      if (!customerId) return new Response('customerId manquant', { status: 400, headers: { ...corsHeaders } });

      const params = new URLSearchParams({ customer: customerId });
      if (returnUrl) params.set('return_url', returnUrl);

      const resp = await fetch('https://api.stripe.com/v1/billing_portal/sessions', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${env.STRIPE_SECRET_KEY}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params,
        
      });
      if (!resp.ok) {
        const txt = await resp.text();
        return new Response(`Stripe API error: ${txt}`, { status: 500, headers: { ...corsHeaders } });
      }
      return new Response(await resp.text(), { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
    }

    return new Response('Not found', { status: 404, headers: { ...corsHeaders } });
  },
};


