# algolia scripts

Every script reads credentials from `ALGOLIA_APP_ID` and `ALGOLIA_API_KEY`.
`lib.mjs` loads `scripts/algolia/.env` first. That file is gitignored. Run
`npm install` once in this directory.

```sh
cp .env.example .env
echo "ALGOLIA_APP_ID=QPBQ67WNIG" > .env
echo "ALGOLIA_API_KEY=$(op read op://private/algolia/admin-key)" >> .env
```

Real env vars still win over `.env`, so a one-off override works:

```sh
ALGOLIA_APP_ID=other ./delete-indices-on-app.mjs --match='^tmp-' --yes
```

## delete-indices-on-app.mjs

Selects indices, prints them, deletes them only with `--yes`.

```sh
./delete-indices-on-app.mjs --stale-days=14          # dry run
./delete-indices-on-app.mjs --stale-days=14 --yes
./delete-indices-on-app.mjs 20m-records 100m-records --yes
./delete-indices-on-app.mjs --match='^tmp-' --yes
./delete-indices-on-app.mjs --match='-records$' --stale-days=30 --yes
```

Filters combine with AND. Algolia refuses to delete a replica that is still
attached to its primary. Detach it first.

`listIndices` returns the first page only. Add pagination above 100 indices.

## upload-records-from-file.mjs

```sh
./upload-records-from-file.mjs records.json 20m-records                      # append to existing index
./upload-records-from-file.mjs records.json 20m-records --clear              # delete index first
./upload-records-from-file.mjs records.json 20m-records --limit=1000         # smoke test, first 1000 records
./upload-records-from-file.mjs records.json 20m-records --clear --limit=100000 --batch=5000
./upload-records-from-file.mjs records.json 20m-records --suffix                # 20m-records-2026-09-08T10-12-00-000Z
./upload-records-from-file.mjs records.json 20m-records --suffix=eu             # 20m-records-eu
./upload-records-from-file.mjs records-100m-metis-replication-eu.json 100m-records --clear --batch=10000
```

The file needs one JSON record per line. NDJSON works. A pretty-printed JSON
array works as long as each record sits on its own line.

`--suffix` builds a fresh index name from the positional one. Bare `--suffix`
appends a UTC timestamp. `--suffix=name` appends `name`.

`--limit=N` stops after N records. Use it to check the mapping before a full
run. `--batch` sets records per `saveObjects` call.

## check-index-on-clusters.mjs

```sh
./check-index-on-clusters.mjs 20m-records --clusters=r12-eu,m1-use
./check-index-on-clusters.mjs 100m-records --clusters=r12-eu,m1-use --gap=10000
```

Samples each cluster machine twice to report entry counts, write activity, and
whether the clusters are in sync. `--gap` is the milliseconds between the two
samples (default 4000). Raise it when writes are slow.
