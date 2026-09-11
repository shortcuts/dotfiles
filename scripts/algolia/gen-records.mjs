#!/usr/bin/env node
// One JSON record per line inside an array, so upload-records-from-file.mjs
// can stream it without a JSON parser.
import { createWriteStream } from 'node:fs';
import { once } from 'node:events';

const args = process.argv.slice(2);
const opts = new Map(
  args.filter((a) => a.startsWith('--')).map((a) => {
    const [k, v = 'true'] = a.replace(/^--/, '').split('=');
    return [k, v];
  }),
);
const out = args.find((a) => !a.startsWith('--')) ?? '200m.json';
const total = Number(opts.get('count') ?? 200_000_000);
const startID = Number(opts.get('start') ?? 0);

// xorshift32 beats Math.random here and keeps runs reproducible.
let s = (Number(opts.get('seed') ?? 42) >>> 0) || 1;
const rnd = () => {
  s ^= s << 13;
  s ^= s >>> 17;
  s ^= s << 5;
  s >>>= 0;
  return s / 4294967296;
};
const pick = (a) => a[(rnd() * a.length) | 0];

// Weighted so the mean record lands near 760 B: 200M records -> ~150 GB.
const BUCKETS = [
  [0.88, 300, 500],
  [0.98, 1000, 3000],
  [1.0, 6000, 15000],
];
const targetSize = () => {
  const r = rnd();
  for (const [cut, lo, hi] of BUCKETS) if (r <= cut) return (lo + rnd() * (hi - lo)) | 0;
  return 400;
};

// ASCII only, no quote or backslash, so char length == byte length and no escaping.
const WORDS = ('wireless bluetooth portable rechargeable compact ultra premium refurbished ' +
  'stainless titanium aluminum carbon ceramic silicone leather canvas nylon polymer ' +
  'speaker headphone monitor keyboard adapter charger cable mount bracket enclosure ' +
  'sensor module battery cartridge filter nozzle gasket bearing spindle actuator ' +
  'lumens hertz watts ohms microns kelvin nits ' +
  'ships from warehouse includes manual and mounting hardware limited warranty ' +
  'compatible with most standard fittings sold individually not for resale ' +
  'designed tested assembled inspected calibrated packaged').split(' ').filter(Boolean);
const ADJ = ['Compact', 'Pro', 'Ultra', 'Elite', 'Classic', 'Rugged', 'Slim', 'Max', 'Nano', 'Titan'];
const NOUN = ['Speaker', 'Camera', 'Router', 'Drone', 'Blender', 'Monitor', 'Mixer', 'Vacuum', 'Printer', 'Scanner', 'Thermostat', 'Doorbell'];
const BRAND = ['Pogoplug', '360fly', '3DR', '3M', 'Acme', 'Northwind', 'Brightline', 'Kelvor', 'Vantek', 'Orbisonic', 'Halcyon', 'Ferrite'];
const CAT = ['Best Buy Gift Cards', 'Cameras & Camcorders', 'Toys, Games & Drones', 'Appliances', 'Audio', 'Computers & Tablets', 'Smart Home', 'Wearable Technology', 'Car Electronics'];

let POOL = '';
while (POOL.length < 1 << 17) POOL += pick(WORDS) + ' ';

const filler = (n) => {
  if (n <= 0) return '';
  let str = POOL.slice((rnd() * (POOL.length >> 1)) | 0);
  while (str.length < n) str += POOL;
  return str.slice(0, n);
};

const stream = createWriteStream(out);
const write = async (chunk) => {
  if (!stream.write(chunk)) await once(stream, 'drain');
};

const FLUSH = 4096;
let buf = [];
let bytes = 0;
const t0 = Date.now();

await write('[\n');
for (let i = 0; i < total; i++) {
  const id = String(startID + i);
  const head =
    `{"name":"${pick(ADJ)} ${pick(NOUN)} ${pick(BRAND)} #${id}","brand":"${pick(BRAND)}"` +
    `,"categories":["${pick(CAT)}"],"price":${(rnd() * 5000) | 0},"rating":${1 + ((rnd() * 5) | 0)}` +
    `,"popularity":${(rnd() * 1e6) | 0},"objectID":"${id}","description":"`;
  const tail = i === total - 1 ? '"}\n' : '"},\n';
  buf.push(head + filler(targetSize() - head.length - tail.length) + tail);

  if (buf.length === FLUSH) {
    const chunk = buf.join('');
    bytes += chunk.length;
    buf = [];
    await write(chunk);
    if (i % (8 * 1024 * 1024) < FLUSH) {
      const secs = (Date.now() - t0) / 1000;
      const gb = bytes / 1e9;
      process.stderr.write(
        `${i + 1}/${total} recs  ${gb.toFixed(1)} GB  ${((i / secs) | 0)} rec/s  eta ${(((total - i) / (i / secs)) / 60) | 0}m\n`,
      );
    }
  }
}
if (buf.length) {
  const chunk = buf.join('');
  bytes += chunk.length;
  await write(chunk);
}
await write(']\n');
stream.end();
await once(stream, 'finish');
process.stderr.write(`done: ${total} records, ${(bytes / 1e9).toFixed(2)} GB in ${((Date.now() - t0) / 60000).toFixed(1)}m\n`);
