// ─────────────────────────────────────────────────────────────────────────
//  Closero — RevenueCat Web Billing init (Phase 2 scaffold)
//  Sells the Closer subscription on the web (RevenueCat → Stripe underneath).
//
//  SETUP (one time — see the Phase 2 setup doc):
//   1. app.revenuecat.com → create a project.
//   2. Connect Stripe as the payment processor (Web Billing).
//   3. Create Entitlement id "closer".
//   4. Create products/prices ($15.99/mo, $129/yr) and an Offering with a
//      "monthly" and "annual" package, both attached to the "closer" entitlement.
//   5. Project settings → API keys → copy the **Web Billing public key**
//      (starts with "rcb_") into RC_WEB_API_KEY below.
//
//  The public key is safe to ship (like the Firebase config).
//  Server-side entitlement truth is written to Firestore by the webhook
//  (see functions/revenuecat-webhook.js) — the client SDK below is for UI.
// ─────────────────────────────────────────────────────────────────────────

import { Purchases } from "https://cdn.jsdelivr.net/npm/@revenuecat/purchases-js/+esm";

// ── PASTE YOUR REVENUECAT WEB BILLING PUBLIC KEY HERE ───────────────────
const RC_WEB_API_KEY = "PASTE_RC_WEB_BILLING_KEY"; // e.g. "rcb_xxxxxxxxxxxxxxxxxx"
// ────────────────────────────────────────────────────────────────────────

export const RC_ENTITLEMENT = "closer";
export const RC_CONFIGURED = !RC_WEB_API_KEY.startsWith("PASTE");

let purchases = null;

// Call once after Firebase auth resolves, with appUserId = Firebase uid.
// Using the same id on web + (later) mobile keeps entitlements unified.
export function rcInit(appUserId) {
  if (!RC_CONFIGURED) return null;
  if (!purchases) {
    purchases = Purchases.configure({ apiKey: RC_WEB_API_KEY, appUserId });
  }
  return purchases;
}

// Is the current user entitled to Closer right now? (client view; UI only)
export async function rcIsCloser() {
  if (!purchases) return false;
  try { return await purchases.isEntitledTo(RC_ENTITLEMENT); }
  catch (e) { console.warn("[closero] rcIsCloser failed:", e); return false; }
}

// Present the RevenueCat/Stripe checkout for the monthly or annual package.
// which = "monthly" | "annual". Returns the purchase result on success.
export async function rcPurchase(which, customerEmail) {
  if (!purchases) throw new Error("RevenueCat not configured");
  const { current } = await purchases.getOfferings();
  if (!current) throw new Error("No current offering configured in RevenueCat");
  const pkg = which === "annual" ? current.annual : current.monthly;
  if (!pkg) throw new Error('Offering is missing a "' + which + '" package');
  return await purchases.purchase({ rcPackage: pkg, customerEmail });
}
