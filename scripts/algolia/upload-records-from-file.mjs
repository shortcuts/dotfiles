#!/usr/bin/env node
// Streams a record file into an index, one record per line.
import { createReadStream } from 'node:fs';
import { createInterface } from 'node:readline';
import { client, flags, retry } from './lib.mjs';

const { opts, rest } = flags();
const [file, baseName] = rest;
// A bare --suffix stamps the run so repeated uploads never share an index.
const suffix = opts.suffix === true ? new Date().toISOString().replace(/[:.]/g, '-') : opts.suffix;
const indexName = suffix ? `${baseName}-${suffix}` : baseName;
const batchSize = Number(opts.batch ?? 1000);
const limit = opts.limit ? Number(opts.limit) : Infinity;

if (!file || !baseName) {
  console.error(
    'usage: ALGOLIA_APP_ID=.. ALGOLIA_API_KEY=.. upload-records-from-file.mjs <file> <index> [--batch=1000] [--limit=N] [--suffix[=name]] [--clear] [--dry-run]',
  );
  process.exit(1);
}

const algolia = opts['dry-run'] ? null : client();
if (suffix) console.log(`index: ${indexName}`);

if (opts.clear && !opts['dry-run'] && (await algolia.indexExists({ indexName }))) {
  console.log(`deleting index "${indexName}"`);
  const { taskID } = await algolia.deleteIndex({ indexName });
  await algolia.waitForTask({ indexName, taskID });
}

// Accepts NDJSON and pretty-printed JSON arrays that keep one record per line.
// Swap in a streaming JSON parser if a file ever wraps records across lines.
const rl = createInterface({ input: createReadStream(file), crlfDelay: Infinity });
let batch = [];
let count = 0;

const push = opts['dry-run']
  ? async () => {}
  : (objects) => retry(() => algolia.saveObjects({ indexName, objects }), indexName);

for await (const line of rl) {
  const trimmed = line.trim().replace(/,$/, '');
  if (trimmed === '' || trimmed === '[' || trimmed === ']') continue;
  batch.push(JSON.parse(trimmed));
  if (count + batch.length >= limit) break;
  if (batch.length === batchSize) {
    await push(batch);
    count += batch.length;
    batch = [];
    if (count % 100_000 === 0) {
      console.log(`${file}: ${count}  rss ${(process.memoryUsage.rss() / 1e6) | 0} MB`);
    }
  }
}
if (batch.length) {
  await push(batch);
  count += batch.length;
}
console.log(`${file}: done, ${count} records into ${indexName}`);
