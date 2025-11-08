interface PlanConfig {
  prices?: string[];
  entitlements: Record<string, unknown>;
}

export interface Env {
  STRIPE_SECRET_KEY: string;
  STRIPE_WEBHOOK_SECRET: string;
  FIREBASE_PROJECT_ID: string;
  FIREBASE_CLIENT_EMAIL: string;
  FIREBASE_PRIVATE_KEY: string;
}

const encoder = new TextEncoder();

const PLAN_CATALOG: Record<string, PlanConfig> = {
  free: {
    entitlements: {
      maxUsers: 3,
      maxProducts: 200,
      maxOperationsPerMonth: 1000,
      exports: true,
      support: 'community',
    },
  },
  pro: {
    prices: ['price_1SOlYFBefWQoVTT09yR9vm8Y'],
    entitlements: {
      maxUsers: 20,
      maxProducts: 10000,
      maxOperationsPerMonth: 100000,
      exports: true,
      support: 'priority',
    },
  },
};

const PRICE_TO_PLAN: Record<string, string> = {};
for (const [planKey, config] of Object.entries(PLAN_CATALOG)) {
  for (const priceId of config.prices ?? []) {
    PRICE_TO_PLAN[priceId] = planKey;
  }
}

const GOOGLE_OAUTH_TOKEN_ENDPOINT = 'https://oauth2.googleapis.com/token';

type FirestoreValue =
  | { nullValue: null }
  | { booleanValue: boolean }
  | { stringValue: string }
  | { integerValue: string }
  | { doubleValue: number }
  | { timestampValue: string }
  | { arrayValue: { values: FirestoreValue[] } }
  | { mapValue: { fields: Record<string, FirestoreValue> } };

let cachedAccessToken: { token: string; expiry: number } | null = null;

function normalizePrivateKey(pem: string): string {
  return pem.replace(/\\n/g, '\n');
}

function base64UrlEncode(input: string | Uint8Array | ArrayBuffer): string {
  let bytes: Uint8Array;
  if (typeof input === 'string') {
    bytes = encoder.encode(input);
  } else if (input instanceof ArrayBuffer) {
    bytes = new Uint8Array(input);
  } else {
    bytes = input;
  }
  let binary = '';
  for (let i = 0; i < bytes.length; i += 1) {
    binary += String.fromCharCode(bytes[i]);
  }
  const base64 = btoa(binary);
  return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/u, '');
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const normalized = normalizePrivateKey(pem)
    .replace(/-----BEGIN PRIVATE KEY-----/u, '')
    .replace(/-----END PRIVATE KEY-----/u, '')
    .replace(/\s+/gu, '');
  const binary = atob(normalized);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const keyData = pemToArrayBuffer(pem);
  return crypto.subtle.importKey(
    'pkcs8',
    keyData,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  );
}

async function createJwt(env: Env): Promise<string> {
  if (!env.FIREBASE_CLIENT_EMAIL || !env.FIREBASE_PRIVATE_KEY) {
    throw new Error('FIREBASE_CLIENT_EMAIL ou FIREBASE_PRIVATE_KEY manquant');
  }
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: env.FIREBASE_CLIENT_EMAIL,
    scope: 'https://www.googleapis.com/auth/datastore',
    aud: GOOGLE_OAUTH_TOKEN_ENDPOINT,
    iat: now,
    exp: now + 3600,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(payload));
  const signatureInput = `${encodedHeader}.${encodedPayload}`;
  const privateKey = await importPrivateKey(env.FIREBASE_PRIVATE_KEY);
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    encoder.encode(signatureInput)
  );
  const encodedSignature = base64UrlEncode(signature);
  return `${signatureInput}.${encodedSignature}`;
}

async function getAccessToken(env: Env): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && cachedAccessToken.expiry - 60 > now) {
    return cachedAccessToken.token;
  }

  const assertion = await createJwt(env);
  const response = await fetch(GOOGLE_OAUTH_TOKEN_ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Impossible de récupérer un access token Google: ${text}`);
  }
  const json = await response.json() as { access_token: string; expires_in?: number };
  const expiresIn = json.expires_in ?? 3600;
  cachedAccessToken = { token: json.access_token, expiry: now + expiresIn };
  return json.access_token;
}

function toFirestoreValue(value: unknown): FirestoreValue {
  if (value === null) {
    return { nullValue: null };
  }
  if (typeof value === 'string') {
    return { stringValue: value };
  }
  if (typeof value === 'boolean') {
    return { booleanValue: value };
  }
  if (typeof value === 'number') {
    if (Number.isFinite(value) && Math.floor(value) === value) {
      return { integerValue: value.toString() };
    }
    return { doubleValue: value };
  }
  if (value instanceof Date) {
    return { timestampValue: value.toISOString() };
  }
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(toFirestoreValue) } };
  }
  if (typeof value === 'object' && value !== null) {
    return {
      mapValue: {
        fields: encodeFirestoreFields(value as Record<string, unknown>),
      },
    };
  }
  throw new Error(`Type non supporté pour Firestore: ${typeof value}`);
}

function encodeFirestoreFields(data: Record<string, unknown>): Record<string, FirestoreValue> {
  const entries: [string, FirestoreValue][] = [];
  for (const [key, value] of Object.entries(data)) {
    if (typeof value === 'undefined') continue;
    entries.push([key, toFirestoreValue(value)]);
  }
  return Object.fromEntries(entries);
}

async function updateTenantDocument(env: Env, tenantId: string, data: Record<string, unknown>): Promise<void> {
  if (!env.FIREBASE_PROJECT_ID) {
    throw new Error('FIREBASE_PROJECT_ID manquant');
  }
  const filteredEntries = Object.entries(data).filter(([, value]) => typeof value !== 'undefined');
  if (!filteredEntries.length) return;

  const token = await getAccessToken(env);
  const url = new URL(
    `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/tenants/${tenantId}`
  );
  for (const [key, value] of filteredEntries) {
    if (value === undefined) continue;
    url.searchParams.append('updateMask.fieldPaths', key);
  }
  const response = await fetch(url.toString(), {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields: encodeFirestoreFields(Object.fromEntries(filteredEntries)) }),
  });
  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Échec mise à jour tenant ${tenantId}: ${response.status} ${text}`);
  }
}

async function findTenantIdByStripeCustomer(env: Env, customerId: string | undefined): Promise<string | null> {
  if (!customerId) return null;
  const token = await getAccessToken(env);
  const response = await fetch(
    `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents:runQuery`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        structuredQuery: {
          from: [{ collectionId: 'tenants' }],
          where: {
            fieldFilter: {
              field: { fieldPath: 'stripeCustomerId' },
              op: 'EQUAL',
              value: { stringValue: customerId },
            },
          },
          limit: 1,
        },
      }),
    }
  );
  if (!response.ok) {
    const text = await response.text();
    console.error('findTenantIdByStripeCustomer error:', text);
    return null;
  }
  const results = await response.json() as Array<{ document?: { name?: string } }>;
  for (const result of results) {
    const name = result.document?.name;
    if (name) {
      const segments = name.split('/');
      return segments[segments.length - 1] ?? null;
    }
  }
  return null;
}

function getStripeId(value: unknown): string | undefined {
  if (!value) return undefined;
  if (typeof value === 'string') return value;
  if (typeof value === 'object' && value !== null && 'id' in value) {
    const id = (value as { id?: unknown }).id;
    return typeof id === 'string' ? id : undefined;
  }
  return undefined;
}

function planFromPrice(priceId: string | undefined | null): { key: string; entitlements: Record<string, unknown> } | null {
  if (!priceId) return null;
  const planKey = PRICE_TO_PLAN[priceId];
  if (!planKey) return null;
  const config = PLAN_CATALOG[planKey];
  if (!config) return null;
  return { key: planKey, entitlements: config.entitlements };
}

function resolvePlan(subscription: any, fallbackPriceId?: string | null): { key: string; entitlements: Record<string, unknown> } | null {
  if (subscription?.metadata?.plan && PLAN_CATALOG[subscription.metadata.plan]) {
    const planKey = subscription.metadata.plan as string;
    return { key: planKey, entitlements: PLAN_CATALOG[planKey].entitlements };
  }
  const priceId =
    subscription?.items?.data?.[0]?.price?.id ??
    fallbackPriceId ??
    subscription?.plan?.id;
  return planFromPrice(priceId);
}

async function fetchStripeSubscription(env: Env, subscriptionId: string): Promise<any> {
  const response = await fetch(`https://api.stripe.com/v1/subscriptions/${subscriptionId}`, {
    method: 'GET',
    headers: { Authorization: `Bearer ${env.STRIPE_SECRET_KEY}` },
  });
  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Stripe subscription fetch failed: ${text}`);
  }
  return response.json();
}

function unixToIso(unixSeconds: number | null | undefined): string | undefined {
  if (!unixSeconds && unixSeconds !== 0) return undefined;
  return new Date(unixSeconds * 1000).toISOString();
}

async function synchronizeSubscription(
  env: Env,
  subscription: any,
  fallbackTenantId?: string | null
): Promise<void> {
  const customerId = getStripeId(subscription.customer);
  const tenantId =
    subscription?.metadata?.tenantId ??
    fallbackTenantId ??
    (await findTenantIdByStripeCustomer(env, customerId));

  if (!tenantId) {
    console.warn('Subscription sans tenantId détecté', subscription.id);
    return;
  }

  const plan = resolvePlan(subscription);
  const fields: Record<string, unknown> = {
    stripeCustomerId: customerId ?? null,
    stripeSubscriptionId: subscription.id ?? null,
    billingStatus: subscription.status ?? 'active',
    billingCurrentPeriodEnd: unixToIso(subscription.current_period_end),
    billingUpdatedAt: new Date().toISOString(),
  };

  if (plan) {
    fields.plan = plan.key;
    fields.entitlements = plan.entitlements;
  }

  await updateTenantDocument(env, tenantId, fields);
}

async function handleCheckoutSessionCompleted(env: Env, session: any): Promise<void> {
  const subscriptionId = getStripeId(session.subscription);
  const customerId = getStripeId(session.customer);
  const fallbackTenantId =
    session.client_reference_id ??
    session.metadata?.tenantId ??
    (await findTenantIdByStripeCustomer(env, customerId));

  if (!subscriptionId) {
    console.warn('Checkout sans subscription ID', session.id);
    if (fallbackTenantId) {
      await updateTenantDocument(env, fallbackTenantId, {
        stripeCustomerId: customerId ?? null,
        billingStatus: 'incomplete',
        billingUpdatedAt: new Date().toISOString(),
      });
    }
    return;
  }

  try {
    const subscription = await fetchStripeSubscription(env, subscriptionId);
    if (!subscription.metadata) subscription.metadata = {};
    if (fallbackTenantId && !subscription.metadata.tenantId) {
      subscription.metadata.tenantId = fallbackTenantId;
    }
    await synchronizeSubscription(env, subscription, fallbackTenantId);
  } catch (error) {
    console.error('Erreur handleCheckoutSessionCompleted:', error);
    throw error;
  }
}

async function handleSubscriptionUpdated(env: Env, subscription: any): Promise<void> {
  try {
    await synchronizeSubscription(env, subscription, subscription?.metadata?.tenantId);
  } catch (error) {
    console.error('Erreur handleSubscriptionUpdated:', error);
    throw error;
  }
}

async function handleSubscriptionDeleted(env: Env, subscription: any): Promise<void> {
  const customerId = getStripeId(subscription.customer);
  const tenantId =
    subscription?.metadata?.tenantId ??
    (await findTenantIdByStripeCustomer(env, customerId));

  if (!tenantId) {
    console.warn('Subscription deleted sans tenantId', subscription.id);
    return;
  }

  const fields: Record<string, unknown> = {
    plan: 'free',
    entitlements: PLAN_CATALOG.free.entitlements,
    stripeCustomerId: customerId ?? null,
    stripeSubscriptionId: null,
    billingStatus: subscription.status ?? 'canceled',
    billingCurrentPeriodEnd: unixToIso(subscription.ended_at ?? subscription.current_period_end),
    billingUpdatedAt: new Date().toISOString(),
  };

  await updateTenantDocument(env, tenantId, fields);
}

async function handleInvoicePaid(env: Env, invoice: any): Promise<void> {
  const subscriptionId = getStripeId(invoice.subscription);
  if (!subscriptionId) return;
  try {
    const subscription = await fetchStripeSubscription(env, subscriptionId);
    await synchronizeSubscription(env, subscription, subscription.metadata?.tenantId);
  } catch (error) {
    console.error('Erreur handleInvoicePaid:', error);
    throw error;
  }
}

async function handleStripeEvent(env: Env, event: any): Promise<void> {
  switch (event.type) {
    case 'checkout.session.completed':
      await handleCheckoutSessionCompleted(env, event.data.object);
      break;
    case 'customer.subscription.created':
    case 'customer.subscription.updated':
      await handleSubscriptionUpdated(env, event.data.object);
      break;
    case 'customer.subscription.deleted':
      await handleSubscriptionDeleted(env, event.data.object);
      break;
    case 'invoice.paid':
      await handleInvoicePaid(env, event.data.object);
      break;
    default:
      console.log(`Événement Stripe non géré: ${event.type}`);
  }
}

// --- Helpers cryptographiques pour la vérification de signature Stripe ---
async function hmacSHA256Hex(secret: string, data: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', key, encoder.encode(data));
  const bytes = new Uint8Array(sig);
  return Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('');
}

function parseStripeSignatureHeader(header: string | null): { t: string; v1: string[] } | null {
  if (!header) return null;
  const parts = header.split(',').map(p => p.trim());
  const t = parts.find(p => p.startsWith('t='))?.split('=')[1] ?? '';
  const v1 = parts
    .filter(p => p.startsWith('v1='))
    .map(p => p.split('=')[1])
    .filter(Boolean);
  return t && v1.length ? { t, v1 } : null;
}

async function verifyStripeSignature(env: Env, request: Request, payloadText: string): Promise<boolean> {
  const sigHeader = request.headers.get('Stripe-Signature');
  const parsed = parseStripeSignatureHeader(sigHeader);
  if (!parsed) return false;

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

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: { ...corsHeaders } });
    }

    if (request.method === 'POST' && url.pathname === '/stripe/webhook') {
      const payloadText = await request.text();
      const valid = await verifyStripeSignature(env, request, payloadText);
      if (!valid) {
        return new Response('Invalid signature', { status: 400, headers: { ...corsHeaders } });
      }

      try {
        const event = JSON.parse(payloadText);
        await handleStripeEvent(env, event);
        return new Response('ok', { status: 200, headers: { ...corsHeaders } });
      } catch (error) {
        console.error('Webhook processing error:', error);
        return new Response('Webhook error', { status: 500, headers: { ...corsHeaders } });
      }
    }

    if (request.method === 'POST' && url.pathname === '/checkout/session') {
      const body: any = await request.json().catch(() => ({}));
      const priceId = body.priceId as string | undefined;
      const successUrl = body.successUrl as string | undefined;
      const cancelUrl = body.cancelUrl as string | undefined;
      const customerId = body.customerId as string | undefined;
      const tenantId = body.tenantId as string | undefined;

      if (!priceId || !successUrl || !cancelUrl || !tenantId) {
        return new Response('Paramètres manquants', { status: 400, headers: { ...corsHeaders } });
      }

      const plan = planFromPrice(priceId);
      if (!plan) {
        return new Response('Price Stripe inconnu', { status: 400, headers: { ...corsHeaders } });
      }

      const params = new URLSearchParams({
        mode: 'subscription',
        'line_items[0][price]': priceId,
        'line_items[0][quantity]': '1',
        success_url: successUrl,
        cancel_url: cancelUrl,
        client_reference_id: tenantId,
        'metadata[tenantId]': tenantId,
        'metadata[priceId]': priceId,
        'metadata[plan]': plan.key,
        'subscription_data[metadata][tenantId]': tenantId,
        'subscription_data[metadata][priceId]': priceId,
        'subscription_data[metadata][plan]': plan.key,
      });

      if (customerId) {
        params.set('customer', customerId);
      }

      const response = await fetch('https://api.stripe.com/v1/checkout/sessions', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${env.STRIPE_SECRET_KEY}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params,
      });

      if (!response.ok) {
        const text = await response.text();
        return new Response(`Stripe API error: ${text}`, { status: 500, headers: { ...corsHeaders } });
      }

      return new Response(await response.text(), {
        status: 200,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    if (request.method === 'POST' && url.pathname === '/billing/portal') {
      const body: any = await request.json().catch(() => ({}));
      const customerId = body.customerId as string | undefined;
      const returnUrl = body.returnUrl as string | undefined;
      if (!customerId) {
        return new Response('customerId manquant', { status: 400, headers: { ...corsHeaders } });
      }

      const params = new URLSearchParams({ customer: customerId });
      if (returnUrl) params.set('return_url', returnUrl);

      const response = await fetch('https://api.stripe.com/v1/billing_portal/sessions', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${env.STRIPE_SECRET_KEY}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params,
      });

      if (!response.ok) {
        const text = await response.text();
        return new Response(`Stripe API error: ${text}`, { status: 500, headers: { ...corsHeaders } });
      }

      return new Response(await response.text(), {
        status: 200,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    return new Response('Not found', { status: 404, headers: { ...corsHeaders } });
  },
};

