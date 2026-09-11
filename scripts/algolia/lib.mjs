import { existsSync } from 'node:fs';
import { algoliasearch } from 'algoliasearch';

// Keys live in an untracked .env next to these scripts, not in the shell history.
const envFile = new URL('.env', import.meta.url).pathname;
if (existsSync(envFile)) process.loadEnvFile(envFile);

export function flags(argv = process.argv.slice(2)) {
  const opts = {};
  const rest = [];
  for (const arg of argv) {
    if (arg.startsWith('--')) {
      const [key, value] = arg.slice(2).split('=');
      opts[key] = value ?? true;
    } else {
      rest.push(arg);
    }
  }
  return { opts, rest };
}

export function client(extra) {
  const appId = process.env.ALGOLIA_APP_ID;
  const apiKey = process.env.ALGOLIA_API_KEY;
  if (!appId || !apiKey) {
    console.error(`set ALGOLIA_APP_ID and ALGOLIA_API_KEY in ${envFile} or the environment`);
    process.exit(1);
  }
  return algoliasearch(appId, apiKey, extra);
}

// Hits one cluster machine directly, so replication lag between an app's
// clusters shows up instead of being hidden behind the load-balanced DSN host.
export function clusterClient(cluster) {
  return client({ hosts: [{ url: `${cluster}.algolia.net`, accept: 'readWrite', protocol: 'https' }] });
}

export async function retry(fn, label, attempts = 5) {
  for (let attempt = 1; ; attempt++) {
    try {
      return await fn();
    } catch (e) {
      if (attempt >= attempts) throw e;
      const wait = 2 ** attempt * 1000;
      console.error(`${label}: retry ${attempt} in ${wait}ms: ${e.message}`);
      await new Promise((r) => setTimeout(r, wait));
    }
  }
}
