// ─────────────────────────────────────────────────────────────────────────
//  Closero — Firebase Auth init (shared by login / signup / reset / verify)
//  Phase 1 of the Auth, Billing & Entitlements plan.
//
//  SETUP (one time):
//   1. console.firebase.google.com → create project "closero-prod"
//   2. Build → Authentication → Get started → enable:
//        • Email/Password
//        • Google
//        • Apple   (needs an Apple Developer account; can skip for now)
//   3. Project settings (gear) → Your apps → </> Web app → register →
//        copy the firebaseConfig values into FIREBASE_CONFIG below.
//   4. Authentication → Settings → Authorized domains → add your domain
//        (e.g. closero.app and closero.pages.dev). localhost is allowed by default.
//
//  These config values are NOT secrets — they're safe to commit and ship.
// ─────────────────────────────────────────────────────────────────────────

import { initializeApp } from "https://www.gstatic.com/firebasejs/11.6.1/firebase-app.js";
import {
  getAuth, setPersistence, browserLocalPersistence,
  createUserWithEmailAndPassword, signInWithEmailAndPassword,
  signInWithPopup, GoogleAuthProvider, OAuthProvider,
  sendPasswordResetEmail, sendEmailVerification,
  onAuthStateChanged, signOut
} from "https://www.gstatic.com/firebasejs/11.6.1/firebase-auth.js";
import {
  getFirestore, doc, getDoc, setDoc, collection, addDoc, serverTimestamp
} from "https://www.gstatic.com/firebasejs/11.6.1/firebase-firestore.js";

// ── PASTE YOUR CONFIG HERE ──────────────────────────────────────────────
const FIREBASE_CONFIG = {
   apiKey: "AIzaSyBQHV40AAxbYtFDdNJP_OtW9W1FFmQFDzA",
  authDomain: "closero.firebaseapp.com",
  projectId: "closero",
  storageBucket: "closero.firebasestorage.app",
  messagingSenderId: "751996788920",
  appId: "1:751996788920:web:c476d09cde4304f6e5944d",
  measurementId: "G-5JJEJ283H7"
};
// ────────────────────────────────────────────────────────────────────────

// Where a fully signed-in + verified user lands. No real app yet, so this is
// a placeholder page. Change this one line when the real app exists.
export const POST_AUTH = "app.html";

// ── LAUNCH SWITCH ───────────────────────────────────────────────────────
// true  = pre-launch "early access" mode (signups join a list, no upgrades).
// false = full launched product.
// Flip to false when the product is ready — that alone returns the site to
// the shipped experience (app.html shows plan/upgrade instead of the wall).
export const EARLY_ACCESS = true;
// ────────────────────────────────────────────────────────────────────────

// True once real config is pasted in. Pages use this to show a friendly
// "connect Firebase" notice instead of throwing confusing SDK errors.
export const IS_CONFIGURED = !FIREBASE_CONFIG.apiKey.startsWith("PASTE");

let auth = null, googleProvider = null, appleProvider = null, db = null;

if (IS_CONFIGURED) {
  const app = initializeApp(FIREBASE_CONFIG);
  auth = getAuth(app);
  db = getFirestore(app);
  // Keep users signed in across tabs/reloads.
  setPersistence(auth, browserLocalPersistence).catch(() => {});
  googleProvider = new GoogleAuthProvider();
  appleProvider = new OAuthProvider("apple.com");
}

// Current month key for the free-tier usage counter, e.g. "2026-07".
function currentUsageMonth() {
  const n = new Date();
  return n.getFullYear() + "-" + String(n.getMonth() + 1).padStart(2, "0");
}

// Create users/{uid} on first sign-in if it doesn't exist yet.
// entitlement starts "free"; only the server (RevenueCat webhook) may change it.
// Idempotent + non-throwing so it never blocks the auth redirect.
export async function ensureUserDoc(user) {
  try {
    if (!user || !db) return;
    const ref = doc(db, "users", user.uid);
    const snap = await getDoc(ref);
    if (snap.exists()) return;
    await setDoc(ref, {
      email: user.email || null,
      displayName: user.displayName || null,
      entitlement: "free",
      rcAppUserId: user.uid,
      usageMonth: currentUsageMonth(),
      sessionsUsed: 0,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });
  } catch (e) {
    console.warn("[closero] ensureUserDoc failed:", e && e.code);
  }
}

// ── EARLY-ACCESS WAITLIST ────────────────────────────────────────────────
// No-friction capture: just an email, no account. Writes one doc to the
// `waitlist` collection (see closero-backend/firestore.rules — create-only,
// no read, so the list can't be scraped). Only used while EARLY_ACCESS = true;
// at launch the homepage switches to the real signup flow and this goes idle.
export async function saveWaitlistEmail(email, source) {
  if (!db) throw new Error("not-configured");
  const clean = (email || "").trim().toLowerCase();
  await addDoc(collection(db, "waitlist"), {
    email: clean,
    source: source || "homepage",
    createdAt: serverTimestamp()
  });
}

// Map Firebase error codes → short, human messages.
export function authMessage(code) {
  const m = {
    "auth/invalid-email": "That email doesn't look right.",
    "auth/missing-password": "Enter your password.",
    "auth/weak-password": "Password must be at least 8 characters.",
    "auth/email-already-in-use": "An account already exists for this email. Try logging in.",
    "auth/invalid-credential": "Email or password is incorrect.",
    "auth/wrong-password": "Email or password is incorrect.",
    "auth/user-not-found": "No account found for that email.",
    "auth/too-many-requests": "Too many attempts. Wait a moment and try again.",
    "auth/popup-closed-by-user": "Sign-in window closed before finishing.",
    "auth/popup-blocked": "Your browser blocked the sign-in popup. Allow popups and retry.",
    "auth/network-request-failed": "Network problem. Check your connection and retry."
  };
  return m[code] || "Something went wrong. Please try again.";
}

export {
  auth, db, googleProvider, appleProvider,
  createUserWithEmailAndPassword, signInWithEmailAndPassword,
  signInWithPopup, sendPasswordResetEmail, sendEmailVerification,
  onAuthStateChanged, signOut
};
