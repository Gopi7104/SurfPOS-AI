'use strict';

// Standalone Firebase connectivity check — run via `npm run verify:firebase` from backend/.
// Exercises Auth, Realtime Database, and Storage independently against the real credentials in
// backend/.env, and reports pass/fail per service. This is an operator tool, never run as part of
// the automated test suite — tests never touch a real Firebase project (see
// docs/21_BACKEND_GUIDELINES.md § 11); confirms the "Firebase infrastructure connection"
// prerequisite is actually satisfied, end to end.

const { hasIdentity, getAuth, getDb, getStorageBucket } = require('../src/firebase/admin');

const results = [];

function record(service, ok, detail) {
  results.push({ service, ok });
  console.log(`${ok ? '✓' : '✗'} ${service}: ${detail}`);
}

async function verifyAuth() {
  try {
    await getAuth().listUsers(1);
    record('Auth', true, 'listUsers() succeeded — service-account credentials are valid');
  } catch (error) {
    record('Auth', false, error.message);
  }
}

async function verifyDatabase() {
  try {
    const ref = getDb().ref('_healthcheck');
    await ref.set({ checkedAt: Date.now() });
    const snapshot = await ref.once('value');
    await ref.remove();
    record('Realtime Database', true, `read/write round-trip succeeded (${JSON.stringify(snapshot.val())})`);
  } catch (error) {
    record('Realtime Database', false, error.message);
  }
}

async function verifyStorage() {
  try {
    const [exists] = await getStorageBucket().exists();
    record('Storage', true, `bucket reachable (exists check returned ${exists})`);
  } catch (error) {
    record('Storage', false, error.message);
  }
}

async function main() {
  if (!hasIdentity()) {
    console.error(
      'Firebase Admin identity is not configured — set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, ' +
        'and FIREBASE_PRIVATE_KEY in backend/.env before running this script.',
    );
    process.exitCode = 1;
    return;
  }

  await verifyAuth();
  await verifyDatabase();
  await verifyStorage();

  const failed = results.filter((r) => !r.ok);
  console.log(
    failed.length === 0
      ? '\nAll Firebase services verified successfully.'
      : `\n${failed.length} of ${results.length} service(s) failed verification.`,
  );
  process.exitCode = failed.length === 0 ? 0 : 1;
}

main().finally(() => {
  // Realtime Database holds a persistent connection open — without an explicit exit, this
  // one-shot CLI check would hang indefinitely after printing its results instead of returning.
  process.exit(process.exitCode ?? 0);
});
