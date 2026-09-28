#!/usr/bin/env node
// Compares the API keys each cluster serves, to see whether a key deleted on
// the source lingers on a replica and whether that replica's pods disagree.
import { clusterClient, flags } from './lib.mjs';

const { opts } = flags();
const clusters = (opts.clusters ?? '').split(',').filter(Boolean);
const samples = Number(opts.samples ?? 5);
const gap = Number(opts.gap ?? 1000);
const match = new RegExp(opts.match ?? '');

if (clusters.length < 2) {
  console.error(
    'usage: compare-api-keys-on-clusters.mjs --clusters=<source>,<replica>[,...] e.g. m1351-eu,r10-usw [--samples=5] [--gap=1000] [--match=^replication-probe-]',
  );
  process.exit(1);
}

// The cluster host balances across pods, so one listing can hide a pod that
// still holds a key. Several samples expose a key that comes and goes.
const seen = Object.fromEntries(clusters.map((c) => [c, new Map()]));
for (let s = 0; s < samples; s++) {
  if (s) await new Promise((r) => setTimeout(r, gap));
  await Promise.all(
    clusters.map(async (cluster) => {
      const { keys } = await clusterClient(cluster).listApiKeys();
      for (const k of keys.filter((k) => match.test(k.description ?? ''))) {
        const entry = seen[cluster].get(k.value) ?? { key: k, hits: 0 };
        entry.hits++;
        seen[cluster].set(k.value, entry);
      }
    }),
  );
}

const all = new Map();
for (const c of clusters) for (const [v, { key }] of seen[c]) all.set(v, key);

console.log(`${process.env.ALGOLIA_APP_ID} api keys, ${samples} samples per cluster, match ${match}`);
let diffs = 0;
for (const [value, key] of [...all].sort((a, b) => a[1].createdAt - b[1].createdAt)) {
  const hits = clusters.map((c) => seen[c].get(value)?.hits ?? 0);
  if (hits.every((h) => h === samples)) continue;
  diffs++;
  const age = Math.round(Date.now() / 1000 - key.createdAt);
  const where = clusters.map((c, i) => `${c}=${hits[i]}/${samples}`).join(' ');
  // Only a prefix: the full value is a live credential.
  console.log(`  ${value.slice(0, 8)}… age=${age}s ${where} "${key.description ?? ''}"`);
}
// The union counts a key once even when only one cluster holds it, so it is
// larger than any single cluster's listing.
console.log(diffs ? `  => ${diffs} of ${all.size} keys (union of all clusters) differ` : `  => in sync (${all.size} keys on every sample)`);

// The first cluster is the source: a replica key it lacks is a lost delete.
const [source, ...replicas] = clusters;
console.log(`  ${source}: ${seen[source].size} keys (source)`);
for (const c of replicas) {
  const extra = [...seen[c].keys()].filter((v) => !seen[source].has(v)).length;
  const missing = [...seen[source].keys()].filter((v) => !seen[c].has(v)).length;
  console.log(`  ${c}: ${seen[c].size} keys, ${extra} not on ${source}, ${missing} missing`);
}
