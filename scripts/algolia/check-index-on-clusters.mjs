#!/usr/bin/env node
// Compares one index across the app's cluster machines to expose replication lag.
import { clusterClient, flags } from './lib.mjs';

const { opts, rest } = flags();
const [indexName] = rest;
const clusters = (opts.clusters ?? '').split(',').filter(Boolean);
const gap = Number(opts.gap ?? 4000);

if (!indexName || !clusters.length) {
  console.error(
    'usage: ALGOLIA_APP_ID=.. ALGOLIA_API_KEY=.. check-index-on-clusters.mjs <index> --clusters=r12-eu,m1-use [--gap=4000]',
  );
  process.exit(1);
}

const stat = async (cluster) => {
  const { items } = await clusterClient(cluster).listIndices();
  return items.find((i) => i.name === indexName);
};

// Cluster hosts do not return numberOfPendingTasks, so "is it indexing?" comes
// from sampling twice: a moving updatedAt means writes are still landing. The
// stat snapshot refreshes in coarse jumps, so treat a recent updatedAt as
// indexing too, otherwise a short window misses a busy primary.
const FRESH_MS = 60_000;
const isIndexing = (before, now) => {
  if (!now) return false;
  const moved = before && (now.updatedAt !== before.updatedAt || now.entries !== before.entries);
  return Boolean(moved) || Date.now() - Date.parse(now.updatedAt) < FRESH_MS;
};

const before = await Promise.all(clusters.map(stat));
await new Promise((r) => setTimeout(r, gap));
const stats = await Promise.all(clusters.map(stat));

console.log(`${process.env.ALGOLIA_APP_ID} index "${indexName}"`);
clusters.forEach((cluster, i) => {
  const s = stats[i];
  if (!s) return console.log(`  ${cluster.padEnd(10)} missing`);
  const age = Math.round((Date.now() - Date.parse(s.updatedAt)) / 1000);
  const rate = before[i] ? s.entries - before[i].entries : 0;
  const state = isIndexing(before[i], s)
    ? `INDEXING (+${rate} in ${gap / 1000}s, last write ${age}s ago)`
    : `idle (last write ${age}s ago)`;
  console.log(`  ${cluster.padEnd(10)} entries=${String(s.entries).padStart(10)} dataSize=${s.dataSize} ${state}`);
});

const active = clusters.filter((_, i) => isIndexing(before[i], stats[i]));
console.log(active.length ? `  => indexing on ${active.join(', ')}` : '  => no indexing in progress');

const counts = stats.map((s) => s?.entries ?? null);
const same = counts.every((c) => c === counts[0]);
console.log(same ? `  => in sync (${counts[0]} entries)` : `  => OUT OF SYNC, delta ${Math.max(...counts) - Math.min(...counts)} entries`);
