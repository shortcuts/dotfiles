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
const concurrency = Number(opts.concurrency ?? 1);

if (!file || !baseName) {
  console.error(
    'usage: ALGOLIA_APP_ID=.. ALGOLIA_API_KEY=.. upload-records-from-file.mjs <file> <index> [--batch=1000] [--concurrency=1] [--limit=N] [--suffix[=name]] [--clear] [--dry-run]',
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
const start = Date.now();
let mark = start;
let marked = 0;

const send = opts['dry-run']
  ? async () => {}
  : (objects) => retry(() => algolia.saveObjects({ indexName, objects }), indexName);

// Keeps `concurrency` saveObjects calls in flight so a load test can saturate the API.
const inFlight = new Set();
let failure;
async function push(objects) {
  if (failure) throw failure;
  const p = send(objects)
    .catch((e) => {
      failure ??= e;
    })
    .finally(() => inFlight.delete(p));
  inFlight.add(p);
  if (inFlight.size >= concurrency) await Promise.race(inFlight);
}

for await (const line of rl) {
  const trimmed = line.trim().replace(/,$/, '');
  if (trimmed === '' || trimmed === '[' || trimmed === ']') continue;
  batch.push(JSON.parse(trimmed));
  if (count + batch.length >= limit) break;
  if (batch.length === batchSize) {
    count += batch.length;
    await push(batch);
    batch = [];
    if (count % 100_000 === 0) {
      const now = Date.now();
      const rate = ((count - marked) / (now - mark)) * 1000;
      const avg = (count / (now - start)) * 1000;
      console.log(
        `${file}: ${count}  ${rate.toFixed(0)}/s (avg ${avg.toFixed(0)}/s)  inflight ${inFlight.size}/${concurrency}  rss ${(process.memoryUsage.rss() / 1e6) | 0} MB`,
      );
      mark = now;
      marked = count;
    }
  }
}
if (batch.length) {
  count += batch.length;
  await push(batch);
}
await Promise.all(inFlight);
if (failure) throw failure;
const secs = (Date.now() - start) / 1000;
console.log(
  `${file}: done, ${count} records into ${indexName} in ${secs.toFixed(1)}s (avg ${((count / secs) | 0)}/s)`,
);
