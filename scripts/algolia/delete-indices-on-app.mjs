#!/usr/bin/env node
// Deletes indices on an app: all, by name, by regex, or only stale ones.
import { client, flags } from './lib.mjs';

const { opts, rest } = flags();
const days = opts['stale-days'] === undefined ? null : Number(opts['stale-days']);
const match = opts.match ? new RegExp(opts.match) : null;
const apply = Boolean(opts.yes);

if (!rest.length && !match && days === null) {
  console.error(
    'usage: ALGOLIA_APP_ID=.. ALGOLIA_API_KEY=.. delete-indices-on-app.mjs [name...] [--match=regex] [--stale-days=14] [--yes]',
  );
  process.exit(1);
}

const algolia = client();
const { items } = await algolia.listIndices();
const cutoff = days === null ? null : Date.now() - days * 86_400_000;

const targets = items.filter((i) => {
  if (rest.length && !rest.includes(i.name)) return false;
  if (match && !match.test(i.name)) return false;
  // updatedAt is absent on an index that never took a write, fall back to createdAt.
  if (cutoff !== null && new Date(i.updatedAt ?? i.createdAt).getTime() >= cutoff) return false;
  return true;
});

console.log(`${items.length} indices on ${process.env.ALGOLIA_APP_ID}, ${targets.length} selected`);
for (const i of targets) {
  console.log(`  ${i.name} (${i.entries} records, updated ${i.updatedAt ?? i.createdAt})`);
}

if (!apply) {
  console.log('\ndry run, pass --yes to delete');
  process.exit(0);
}

let failed = 0;
for (const i of targets) {
  try {
    const { taskID } = await algolia.deleteIndex({ indexName: i.name });
    await algolia.waitForTask({ indexName: i.name, taskID });
    console.log(`deleted ${i.name}`);
  } catch (e) {
    // A key scoped to a subset of indices 403s on the rest, keep going instead of aborting the batch.
    if (e.status !== 403) throw e;
    failed++;
    console.error(`skipped ${i.name}: 403 forbidden`);
  }
}
if (failed) console.error(`${failed}/${targets.length} skipped on 403`);
