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

type FirestoreDocument = {
  name?: string;
  fields?: Record<string, FirestoreValue>;
};

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

function getStringField(fields: Record<string, FirestoreValue> | undefined, key: string): string | undefined {
  const v = fields?.[key];
  if (!v) return undefined;
  if ('stringValue' in v) return v.stringValue;
  return undefined;
}

function getBoolField(fields: Record<string, FirestoreValue> | undefined, key: string): boolean | undefined {
  const v = fields?.[key];
  if (!v) return undefined;
  if ('booleanValue' in v) return v.booleanValue;
  return undefined;
}

function getDocumentId(docName: string | undefined): string | undefined {
  if (!docName) return undefined;
  const parts = docName.split('/');
  return parts[parts.length - 1];
}

async function sha256Hex(text: string): Promise<string> {
  const hash = await crypto.subtle.digest('SHA-256', encoder.encode(text));
  const bytes = new Uint8Array(hash);
  return Array.from(bytes)
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
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

async function runQuerySingle(
  env: Env,
  collectionId: string,
  fieldPath: string,
  value: FirestoreValue,
): Promise<FirestoreDocument | null> {
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
          from: [{ collectionId }],
          where: {
            fieldFilter: {
              field: { fieldPath },
              op: 'EQUAL',
              value,
            },
          },
          limit: 1,
        },
      }),
    }
  );

  if (!response.ok) {
    const text = await response.text();
    console.error('runQuerySingle error:', text);
    return null;
  }

  const results = (await response.json()) as Array<{ document?: FirestoreDocument }>;
  for (const result of results) {
    if (result.document) return result.document;
  }
  return null;
}

async function upsertDocument(
  env: Env,
  collectionId: string,
  documentId: string,
  data: Record<string, unknown>,
): Promise<void> {
  const token = await getAccessToken(env);
  const baseUrl = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${collectionId}/${documentId}`;

  const payloadFields = encodeFirestoreFields(data);
  const url = new URL(baseUrl);
  for (const key of Object.keys(data)) {
    url.searchParams.append('updateMask.fieldPaths', key);
  }

  let response = await fetch(url.toString(), {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields: payloadFields }),
  });

  if (response.status === 404) {
    response = await fetch(
      `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${collectionId}?documentId=${documentId}`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ fields: payloadFields }),
      }
    );
  }

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`upsertDocument(${collectionId}/${documentId}) failed: ${response.status} ${text}`);
  }
}

async function updateTenantDocument(env: Env, tenantId: string, data: Record<string, unknown>): Promise<void> {
  if (!env.FIREBASE_PROJECT_ID) {
    throw new Error('FIREBASE_PROJECT_ID manquant');
  }
  const filteredEntries = Object.entries(data).filter(([, value]) => typeof value !== 'undefined');
  if (!filteredEntries.length) return;

  const token = await getAccessToken(env);
  const documentPath = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/tenants/${tenantId}`;
  const url = new URL(documentPath);
  const payloadFields = encodeFirestoreFields(Object.fromEntries(filteredEntries));
  for (const [key, value] of filteredEntries) {
    if (value === undefined) continue;
    url.searchParams.append('updateMask.fieldPaths', key);
  }
  let response = await fetch(url.toString(), {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ fields: payloadFields }),
  });

  if (response.status === 404) {
    // Le document n'existe pas encore : on le crée.
    response = await fetch(
      `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/tenants?documentId=${tenantId}`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ fields: payloadFields }),
      }
    );
    if (response.ok) {
      console.log(`Document tenant créé: ${tenantId}`);
      return;
    }
  }

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

async function ensureMembership(env: Env, firebaseUid: string, tenantId: string, role: string, userId?: string) {
  const membershipId = `${firebaseUid}_${tenantId}`;
  await upsertDocument(env, 'memberships', membershipId, {
    firebaseUid,
    tenantId,
    role,
    userId: userId ?? null,
    createdAt: new Date(),
  });
}

function sanitizeId(input: string): string {
  return input
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9_\- ]/gu, '')
    .replace(/\s+/gu, '_');
}

async function getDocument(env: Env, collectionId: string, documentId: string): Promise<FirestoreDocument | null> {
  const token = await getAccessToken(env);
  const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${collectionId}/${documentId}`;
  const resp = await fetch(url, { method: 'GET', headers: { Authorization: `Bearer ${token}` } });
  if (resp.status === 404) return null;
  if (!resp.ok) {
    const text = await resp.text();
    throw new Error(`getDocument(${collectionId}/${documentId}) failed: ${resp.status} ${text}`);
  }
  return (await resp.json()) as FirestoreDocument;
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

async function handleInvoicePaymentFailed(env: Env, invoice: any): Promise<void> {
  const customerId = getStripeId(invoice.customer);
  const subscriptionId = getStripeId(invoice.subscription);
  
  if (!customerId) {
    console.warn('Invoice payment_failed sans customerId', invoice.id);
    return;
  }

  const tenantId = await findTenantIdByStripeCustomer(env, customerId);
  if (!tenantId) {
    console.warn('Invoice payment_failed sans tenantId trouvé', invoice.id, customerId);
    return;
  }

  const fields: Record<string, unknown> = {
    billingStatus: 'payment_failed',
    billingLastPaymentError: invoice.last_payment_error?.message || 'Échec du paiement',
    billingUpdatedAt: new Date().toISOString(),
  };

  // Si on a l'ID de subscription, on récupère aussi les infos à jour
  if (subscriptionId) {
    try {
      const subscription = await fetchStripeSubscription(env, subscriptionId);
      fields.billingCurrentPeriodEnd = unixToIso(subscription.current_period_end);
    } catch (error) {
      console.error('Erreur fetch subscription dans payment_failed:', error);
    }
  }

  await updateTenantDocument(env, tenantId, fields);
  console.log(`Tenant ${tenantId} marqué payment_failed suite à invoice ${invoice.id}`);
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
    case 'invoice.payment_failed':
      await handleInvoicePaymentFailed(env, event.data.object);
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

    // Auth bootstrap (Firebase Auth anonyme + membership)
    if (request.method === 'POST' && url.pathname === '/auth/bootstrap') {
      try {
        const body: any = await request.json().catch(() => ({}));
        const accessCode = typeof body.accessCode === 'string' ? body.accessCode.trim() : '';
        const firebaseUid = typeof body.firebaseUid === 'string' ? body.firebaseUid.trim() : '';
        if (!accessCode || !firebaseUid) {
          return new Response('Paramètres manquants', { status: 400, headers: { ...corsHeaders } });
        }

        const userDoc = await runQuerySingle(env, 'users', 'code', { stringValue: accessCode });
        if (!userDoc?.fields) {
          return new Response('Code d’accès invalide', { status: 401, headers: { ...corsHeaders } });
        }

        const tenantId = getStringField(userDoc.fields, 'tenantId');
        const name = getStringField(userDoc.fields, 'name') ?? 'Utilisateur';
        const email = getStringField(userDoc.fields, 'email');
        const isAdmin = getBoolField(userDoc.fields, 'isAdmin') ?? false;
        const userId = getDocumentId(userDoc.name);

        if (!tenantId) {
          return new Response('Utilisateur sans tenant', { status: 409, headers: { ...corsHeaders } });
        }

        await ensureMembership(env, firebaseUid, tenantId, isAdmin ? 'admin' : 'employee', userId);

        return new Response(
          JSON.stringify({ id: userId, name, email, tenantId, isAdmin }),
          { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
        );
      } catch (error) {
        console.error('auth/bootstrap error:', error);
        return new Response('Erreur auth', { status: 500, headers: { ...corsHeaders } });
      }
    }

    // Auth tenant (email/mdp custom + membership)
    if (request.method === 'POST' && url.pathname === '/auth/tenant-login') {
      try {
        const body: any = await request.json().catch(() => ({}));
        const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
        const password = typeof body.password === 'string' ? body.password : '';
        const firebaseUid = typeof body.firebaseUid === 'string' ? body.firebaseUid.trim() : '';
        if (!email || !password || !firebaseUid) {
          return new Response('Paramètres manquants', { status: 400, headers: { ...corsHeaders } });
        }

        const userDoc = await runQuerySingle(env, 'users', 'email', { stringValue: email });
        if (!userDoc?.fields) {
          return new Response('Email ou mot de passe incorrect', { status: 401, headers: { ...corsHeaders } });
        }

        const storedHash = getStringField(userDoc.fields, 'password');
        const computedHash = await sha256Hex(password);
        if (!storedHash || storedHash !== computedHash) {
          // Compat: seed démo (si le compte a été créé avec un hash erroné, on le corrige automatiquement)
          const userId = getDocumentId(userDoc.name);
          const isDemoAdmin = email === 'admin@demo.io' && password === 'admin123' && Boolean(userId);
          if (isDemoAdmin && userId) {
            await upsertDocument(env, 'users', userId, { password: computedHash });
          } else {
            return new Response('Email ou mot de passe incorrect', { status: 401, headers: { ...corsHeaders } });
          }
        }

        const isAdmin = getBoolField(userDoc.fields, 'isAdmin') ?? false;
        if (!isAdmin) {
          return new Response('Seuls les administrateurs peuvent accéder à cet espace.', { status: 403, headers: { ...corsHeaders } });
        }

        const tenantId = getStringField(userDoc.fields, 'tenantId');
        const name = getStringField(userDoc.fields, 'name') ?? 'Admin';
        const userId = getDocumentId(userDoc.name);

        if (!tenantId) {
          return new Response('Aucun tenant associé à ce compte.', { status: 409, headers: { ...corsHeaders } });
        }

        await ensureMembership(env, firebaseUid, tenantId, 'admin', userId);

        return new Response(
          JSON.stringify({ id: userId, name, email, tenantId, isAdmin: true }),
          { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
        );
      } catch (error) {
        console.error('auth/tenant-login error:', error);
        return new Response('Erreur auth', { status: 500, headers: { ...corsHeaders } });
      }
    }

    // Signup tenant (création tenant + admin user + membership)
    if (request.method === 'POST' && url.pathname === '/auth/signup') {
      try {
        const body: any = await request.json().catch(() => ({}));
        const name = typeof body.name === 'string' ? body.name.trim() : '';
        const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
        const password = typeof body.password === 'string' ? body.password : '';
        const companyName = typeof body.companyName === 'string' ? body.companyName.trim() : '';
        const firebaseUid = typeof body.firebaseUid === 'string' ? body.firebaseUid.trim() : '';
        if (!name || !email || !password || !companyName || !firebaseUid) {
          return new Response('Paramètres manquants', { status: 400, headers: { ...corsHeaders } });
        }

        let emailExisting: FirestoreDocument | null = null;
        try {
          emailExisting = await runQuerySingle(env, 'users', 'email', { stringValue: email });
        } catch (e: any) {
          return new Response('Erreur inscription (email_check)', { status: 500, headers: { ...corsHeaders } });
        }
        if (emailExisting?.fields) {
          return new Response('Cet email est déjà utilisé', { status: 409, headers: { ...corsHeaders } });
        }

        const tenantId = sanitizeId(companyName);
        if (!tenantId) {
          return new Response('Nom de société invalide', { status: 400, headers: { ...corsHeaders } });
        }
        let existingTenant: FirestoreDocument | null = null;
        try {
          existingTenant = await getDocument(env, 'tenants', tenantId);
        } catch (e: any) {
          return new Response('Erreur inscription (tenant_check)', { status: 500, headers: { ...corsHeaders } });
        }
        if (existingTenant) {
          return new Response('Ce tenant existe déjà', { status: 409, headers: { ...corsHeaders } });
        }

        // Tenant doc
        try {
          await upsertDocument(env, 'tenants', tenantId, {
            name: companyName,
            plan: 'free',
            createdAt: new Date(),
            entitlements: {
              maxUsers: 3,
              maxProducts: 200,
              maxOperationsPerMonth: 1000,
              exports: false,
              support: 'community',
            },
            billingStatus: 'active',
          });
        } catch (e: any) {
          return new Response('Erreur inscription (upsert_tenant)', { status: 500, headers: { ...corsHeaders } });
        }

        // User doc (ID basé sur le nom, avec fallback si collision)
        let userDocId = sanitizeId(name);
        if (!userDocId) userDocId = `user_${Date.now()}`;
        try {
          const collision = await getDocument(env, 'users', userDocId);
          if (collision) {
            userDocId = `${userDocId}_${Math.floor(Math.random() * 10000)}`;
          }
        } catch (e: any) {
          return new Response('Erreur inscription (user_check)', { status: 500, headers: { ...corsHeaders } });
        }

        try {
          await upsertDocument(env, 'users', userDocId, {
            name,
            email,
            password: await sha256Hex(password),
            tenantId,
            isAdmin: true,
            createdAt: new Date(),
          });
        } catch (e: any) {
          return new Response('Erreur inscription (upsert_user)', { status: 500, headers: { ...corsHeaders } });
        }

        try {
          await ensureMembership(env, firebaseUid, tenantId, 'admin', userDocId);
        } catch (e: any) {
          return new Response('Erreur inscription (membership)', { status: 500, headers: { ...corsHeaders } });
        }

        return new Response(
          JSON.stringify({ userId: userDocId, userName: name, tenantId }),
          { status: 200, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
        );
      } catch (error) {
        console.error('auth/signup error:', error);
        return new Response('Erreur inscription', { status: 500, headers: { ...corsHeaders } });
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

    if (request.method === 'POST' && url.pathname === '/billing/invoices') {
      const body: any = await request.json().catch(() => ({}));
      const customerId = body.customerId as string | undefined;
      const limitRaw = Number(body.limit ?? 10);
      const limit = Number.isFinite(limitRaw) ? Math.min(Math.max(Math.trunc(limitRaw), 1), 20) : 10;
      const startingAfter = typeof body.startingAfter === 'string' ? body.startingAfter : undefined;
      const endingBefore = typeof body.endingBefore === 'string' ? body.endingBefore : undefined;

      if (!customerId) {
        return new Response('customerId manquant', { status: 400, headers: { ...corsHeaders } });
      }

      const params = new URLSearchParams({ customer: customerId, limit: String(limit) });
      if (startingAfter) params.set('starting_after', startingAfter);
      if (endingBefore) params.set('ending_before', endingBefore);

      const response = await fetch(`https://api.stripe.com/v1/invoices?${params.toString()}`, {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${env.STRIPE_SECRET_KEY}`,
        },
      });

      if (!response.ok) {
        const text = await response.text();
        return new Response(`Stripe API error: ${text}`, { status: response.status, headers: { ...corsHeaders } });
      }

      return new Response(await response.text(), {
        status: 200,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    return new Response('Not found', { status: 404, headers: { ...corsHeaders } });
  },
};

