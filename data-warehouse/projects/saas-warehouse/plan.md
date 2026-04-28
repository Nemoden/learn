# saas-warehouse — Learning Plan

**Primary Audience**: Claude (AI teaching assistant)
**Purpose**: Teaching script for building an end-to-end analytics pipeline mirroring a real AWS SaaS architecture: DynamoDB + Lambda events → Kinesis Streams / Firehose → Iceberg/Parquet on S3 → Athena → QuickSight. Then layered with dbt and SQLMesh for transformation modeling.

**How Claude Uses This File**:
1. **Resume teaching** — Read "Session State" for current unit and next unchecked item
2. **Teach systematically** — Follow checkboxes sequentially, teaching concepts just-in-time
3. **Track progress** — Check boxes as user completes tasks
4. **Guide interactively** — Walk user through activities, don't just list them
5. **Verify work** — Run scripts, query Iceberg tables, inspect AWS console + CLI, check metadata files, run EXPLAIN, verify dashboard renders

**How User Uses This File** (secondary):
- See what's coming next
- Track overall progress
- Reference MUST-KNOWs and key patterns
- Understand the learning structure

**Teaching Approach**: Goal-driven units. Each unit builds one capability, teaching only the concepts needed for that goal. Real AWS resources from day 1. IaC via **AWS CDK (Python)** — same language as the rest of the project. Each unit ends with a tangible artifact the next unit consumes.

**Cross-Pollination Principle**: At every unit (and the dedicated Unit 10 finale), call out **"Here we could also use X"** — adjacent technologies, alternative tools, what-the-industry-uses-instead. This prevents tunnel vision on the chosen stack.

---

## Overview

```
                  ┌────────────────────┐
   App writes →   │  DynamoDB tables   │
                  └──────────┬─────────┘
                             │ DDB Streams (CDC)
                             ▼
                  ┌────────────────────┐
   Lambda evts →  │  Kinesis Data Str. │  ◄── producer Lambdas
                  └──────────┬─────────┘
                             │ (replay-able, multi-consumer)
                  ┌──────────┴─────────┐
                  ▼                    ▼
          ┌────────────┐       ┌────────────┐
          │  Firehose  │       │ 2nd Lambda │  (parallel consumer)
          │  +Parquet  │       └────────────┘
          │  +xform λ  │
          └─────┬──────┘
                ▼
       ┌──────────────────┐
       │ S3 (Parquet)     │
       │ Iceberg metadata │ ◄── pyiceberg writes
       └────────┬─────────┘
                │ Glue Data Catalog
                ▼
        ┌──────────────┐    ┌────────────┐    ┌──────────┐
        │   Athena     │ ←→ │   dbt      │ ←→ │ SQLMesh  │  (modeling layers)
        └──────┬───────┘    └────────────┘    └──────────┘
               ▼
       ┌──────────────┐
       │  QuickSight  │
       └──────────────┘
```

**Core Goals**: produce a queryable Iceberg warehouse fed by realistic SaaS data sources, modeled into a star schema, surfaced in a dashboard.
**Tools/Materials**: AWS account (existing), Python, pyarrow, pyiceberg, duckdb, AWS CDK (Python), Athena, Glue, Kinesis Data Streams, Firehose, DynamoDB, Lambda, QuickSight, dbt-core + dbt-athena, sqlmesh.

---

## Unit 1: Columnar Storage Fundamentals — "Convert DDB JSON → Parquet, query with DuckDB"

**Goal:** Take a real DynamoDB JSON export and produce well-structured Parquet files; query them locally with DuckDB and reason about size/speed tradeoffs.

**New concepts:** row groups, column chunks, pages, dictionary encoding, RLE, snappy/zstd/gzip compression, predicate pushdown, column pruning, pyarrow Table/Dataset API.

### Key Patterns
- `pyarrow.Table.from_pylist(records)` → write via `pyarrow.parquet.write_table(table, path, compression='zstd', row_group_size=...)`
- DynamoDB JSON has type-tagged values (`{"S": "..."}`, `{"N": "..."}`) — flatten before Parquet
- `duckdb.sql("SELECT ... FROM read_parquet('s3://.../*.parquet')")`
- `EXPLAIN` in DuckDB shows column pruning + predicate pushdown

### Activities
- [ ] Take or generate a DynamoDB JSON export sample (matters/firms/users shape)
- [ ] MUST-KNOW: **Columnar vs row layout** — columnar groups same-typed values together, enabling compression and reading only needed columns. Crucial because warehouse queries scan few columns over many rows.
- [ ] Flatten DDB type-tagged JSON into plain Python dicts
- [ ] Write Parquet with default settings, inspect file size + schema with `parquet-tools` or pyarrow
- [ ] MUST-KNOW: **Row groups** — Parquet's "stripe" unit (default ~128MB). Min/max stats per row group enable predicate pushdown skip-reading.
- [ ] Rewrite with different compressions (snappy, zstd, gzip) — record file size for each
- [ ] MUST-KNOW: **Dictionary encoding** — repeated string values stored once, indexed. Why columnar gets such good compression on low-cardinality columns.
- [ ] Query with DuckDB, run `EXPLAIN` on a filtered query, observe row group skipping
- [ ] Compare query speed: `SELECT *` vs `SELECT one_column WHERE filter` — observe how column pruning + pushdown change the work

### Outcome
✅ **Parquet files on disk derived from a DDB export, queryable by DuckDB, with measured size/speed tradeoffs across compression codecs.**

### What you'll know after Unit 1
- Why columnar beats row for analytics
- How row groups + min/max stats enable pushdown
- Realistic compression ratios for SaaS-shaped data
- pyarrow's Parquet API

### Here we could also use X
- **Apache ORC** — Hive-era columnar format, still common in Hadoop estates
- **Apache Avro** — row-based, popular for Kafka payloads (good for streaming, bad for analytics)
- **Polars** instead of pyarrow — Rust-backed DataFrame, faster on single-node workloads
- **Pandas** — fine for quick scripting, but pyarrow is the native Parquet writer

---

## Unit 2: Iceberg Basics — "Land Parquet in an Iceberg table, query with Athena, time-travel"

**Goal:** Wrap your Parquet files in an Iceberg table on S3 with the Glue catalog, query the same data from both DuckDB and Athena, and run a time-travel query.

**New concepts:** snapshots, manifest files, manifest lists, `metadata.json`, Glue catalog integration, Athena Iceberg support, time-travel via snapshot id / timestamp.

### Key Patterns
- pyiceberg: `Catalog.create_table(identifier, schema, partition_spec, location)`
- `table.append(pyarrow_table)` → produces a new snapshot
- Athena Iceberg: `CREATE TABLE ... TBLPROPERTIES ('table_type'='ICEBERG')` (or use catalog directly)
- Time travel: `SELECT * FROM tbl FOR TIMESTAMP AS OF TIMESTAMP '...'` or `... FOR VERSION AS OF <snapshot_id>`

### Activities
- [ ] CDK stack: provision S3 bucket (warehouse) + Glue database
- [ ] MUST-KNOW: **Open table format** — Iceberg adds a metadata layer over your Parquet files so you get transactions, schema evolution, and snapshots without a database.
- [ ] Configure pyiceberg with the Glue catalog
- [ ] Create an Iceberg table with explicit schema (matters fact-shape)
- [ ] Append the Parquet data from Unit 1 → produces snapshot 1
- [ ] Inspect S3 bucket structure: `data/`, `metadata/v1.metadata.json`, manifest list (`snap-*.avro`), manifests (`*-m0.avro`)
- [ ] MUST-KNOW: **Metadata tree** — `metadata.json` → manifest list → manifests → data files. Each commit produces a new `metadata.json` and snapshot.
- [ ] Append a second batch (mutated rows) → snapshot 2
- [ ] Query latest from Athena (workgroup configured for Iceberg)
- [ ] Query latest from DuckDB via `iceberg_scan('s3://...')` extension
- [ ] Run a time-travel query against snapshot 1
- [ ] MUST-KNOW: **Snapshot isolation** — readers see a consistent view; writers produce new snapshots without blocking readers.

### Outcome
✅ **Iceberg table on S3 cataloged in Glue, queryable from Athena and DuckDB, with verifiable time travel.**

### What you'll know after Unit 2
- Iceberg metadata anatomy
- Glue catalog as Iceberg metastore
- Why open table formats won over Hive-style partition tables
- pyiceberg + Athena Iceberg syntax basics

### Here we could also use X
- **Delta Lake** — Databricks-led; strong if you live in the Databricks ecosystem, weaker AWS-native story
- **Apache Hudi** — older than Iceberg/Delta; strong CDC-merge story (MoR was its forte first); used heavily at Uber
- **Hive** ACID tables — legacy; if you ever inherit a Hive estate
- **REST catalog** instead of Glue — cloud-portable, used by Tabular/Polaris/Lakekeeper
- **Snowflake-managed Iceberg** — Snowflake reads/writes external Iceberg tables; relevant if you ever need Snowflake later

---

## Unit 3: Iceberg Operations — "Schema/partition evolution, CoW vs MoR, compaction, snapshot expiry"

**Goal:** Operate an Iceberg table at production-grade: evolve the schema, change partitioning without rewriting history, choose CoW vs MoR per use case, compact small files, expire old snapshots.

**New concepts:** schema evolution rules (add/rename/drop columns safely), hidden partitioning, partition transforms (`days(ts)`, `bucket(N, col)`, `truncate(N, col)`), Copy-on-Write vs Merge-on-Read, position vs equality deletes, compaction (rewrite_data_files), snapshot expiry, orphan files.

### Key Patterns
- Schema evo: `table.update_schema().add_column(...).rename_column(...).commit()`
- Partition evo: `table.update_spec().add_field('event_date', transforms.day('event_ts')).commit()`
- CoW (default): rewrites whole files on update — fast reads, slower writes
- MoR: writes delete files alongside data — fast writes, slower reads (extra merge at query time)
- Compaction: pyiceberg `rewrite_data_files` action or Athena `OPTIMIZE`
- Expiry: `expire_snapshots` (older than N days, keeping last K)

### Activities
- [ ] Add a column to the Iceberg table — verify old snapshots still query fine (column = null for old rows)
- [ ] MUST-KNOW: **Why schema evolution is safe** — Iceberg uses field IDs internally, not column names; renames are metadata-only.
- [ ] Add a partition spec by `day(event_ts)` after the fact (partition evolution)
- [ ] MUST-KNOW: **Hidden partitioning** — users query on `event_ts`; Iceberg derives the partition automatically, no separate `event_date` column needed in queries.
- [ ] Switch a table to MoR; perform a row-level update; inspect delete files in S3
- [ ] MUST-KNOW: **CoW vs MoR tradeoff** — CoW = write amplification, simple reads. MoR = cheap writes, merge cost at read. Pick MoR for high-update workloads (CDC), CoW for append-mostly + heavy read.
- [ ] Generate many small files (simulate Firehose's small-batch output) → run compaction → measure file count + size before/after
- [ ] Expire old snapshots → confirm time-travel to expired snapshots fails
- [ ] MUST-KNOW: **Orphan files** — files left on S3 not referenced by any snapshot (failed writes, expired). Run `remove_orphan_files` periodically.

### Outcome
✅ **Iceberg table that has been schema-evolved, partition-evolved, compacted, and snapshot-expired — with you able to explain each tradeoff.**

### What you'll know after Unit 3
- Iceberg's field-ID-based safety guarantees
- When to choose CoW vs MoR
- Compaction + expiry maintenance jobs
- Hidden partitioning's value over Hive-style explicit columns

### Here we could also use X
- **AWS Glue Iceberg-managed compaction** — Glue can run compaction for you on schedule
- **Tabular / Polaris / Lakekeeper** — managed Iceberg services (Tabular acquired by Databricks)
- **Apache Spark** for heavy compaction at scale (pyiceberg is fine to mid-scale)

---

## Unit 4: DDB Streams → Firehose → Iceberg — "Land CDC events as warehouse rows"

**Goal:** Wire a real DynamoDB table's change events through Firehose into the Iceberg warehouse with a transform Lambda flattening the DDB JSON shape — all infra in CDK.

**New concepts:** DDB Streams shard model, CDC event shape (`INSERT`/`MODIFY`/`REMOVE`), `NewImage`/`OldImage`/`Keys`, Firehose buffering hints (size + time), Firehose Parquet conversion, transform Lambda contract (record `recordId`, `result`, `data`), Firehose error S3 prefix, IAM least-privilege for cross-service plumbing.

### Key Patterns
- CDK: `dynamodb.Table` with `stream=StreamViewType.NEW_AND_OLD_IMAGES`
- CDK: `kinesisfirehose.DeliveryStream` with `S3Bucket` destination + `DataFormatConversionConfiguration` for Parquet
- Transform Lambda input: `{records: [{recordId, data: <base64>, ...}]}`; output: `{records: [{recordId, result: 'Ok'|'Dropped'|'ProcessingFailed', data: <base64>}]}`
- Firehose buffer: 1–128 MB / 60–900 sec (whichever first)
- Firehose can read DDB Streams via Kinesis Adapter or you wire DDB Streams → Lambda → Firehose `PutRecord` (older pattern). Newer: **DynamoDB → Kinesis Data Stream** (next unit) → Firehose. We'll do the Lambda-bridge pattern here for the basic Firehose mechanics.

### Activities
- [ ] CDK: stand up a `matters` DynamoDB table with stream enabled
- [ ] MUST-KNOW: **DDB Stream event shape** — each record carries `eventName` (INSERT/MODIFY/REMOVE), `dynamodb.NewImage`, `dynamodb.OldImage`, `dynamodb.Keys`. Type-tagged JSON.
- [ ] CDK: provision Firehose delivery stream with Parquet conversion to Glue table
- [ ] MUST-KNOW: **Firehose Parquet conversion needs a Glue table schema** — Firehose looks up the schema to know how to encode columns.
- [ ] CDK: wire DDB Streams → bridge Lambda → `firehose:PutRecordBatch`
- [ ] Implement transform Lambda that flattens DDB JSON into the Glue-table-matching shape
- [ ] MUST-KNOW: **Transform Lambda contract** — return same `recordId` per input record; `result: 'Dropped'` filters out without erroring; `'ProcessingFailed'` sends to error S3 prefix.
- [ ] Insert/update rows in DDB → wait for buffer flush → see Parquet land in S3
- [ ] Query via Athena → confirm CDC rows appear with correct event types
- [ ] MUST-KNOW: **Buffering tradeoff** — small buffer = fresh data + many small files (compaction headache). Large buffer = staler + bigger files.
- [ ] Trigger a `ProcessingFailed` (bad payload) → find it in error S3 prefix
- [ ] Compact the resulting Iceberg table (re-uses Unit 3 skill)

### Outcome
✅ **CDK-deployed DDB → Firehose → Iceberg pipeline writing real CDC events into the warehouse, with error path verified.**

### What you'll know after Unit 4
- DDB Streams event shape + shard semantics
- Firehose buffering, Parquet conversion, transform contract
- CDK patterns for L2 Firehose + DDB constructs
- Why small-batch streaming creates compaction debt

### Here we could also use X
- **AWS DMS** — for one-time migrations or non-DDB sources (RDS → S3)
- **Debezium** — open source CDC for relational DBs (RDS Postgres/MySQL → Kafka)
- **EventBridge Pipes** — managed source-to-target wiring with built-in filter/transform; lighter than Lambda glue
- **AWS Glue Streaming** — heavier transforms via Spark Structured Streaming

---

## Unit 5: Kinesis Data Streams — "Producer Lambda → KDS → Firehose + 2nd Lambda consumer"

**Goal:** Build a multi-consumer streaming spine: backend Lambdas put events to a Kinesis Data Stream; Firehose consumes for warehouse landing; a second Lambda consumes the same stream independently for real-time use.

**New concepts:** shards, partition key → shard hashing, retention (24h–365d), replay (`TRIM_HORIZON`/`AT_TIMESTAMP`), shared throughput vs **enhanced fan-out** (EFO), Kinesis Client Library / Lambda event source mapping, ordering guarantees per partition key.

### Key Patterns
- CDK: `kinesis.Stream(streamMode=ON_DEMAND)` (or `PROVISIONED` with shard count)
- Producer Lambda: `kinesis_client.put_record(StreamName, Data, PartitionKey)`
- Lambda consumer ESM: `EventSourceMapping(eventSourceArn=stream.streamArn, startingPosition=TRIM_HORIZON, batchSize=100)`
- EFO: `register_stream_consumer` per consumer ARN — dedicated 2 MB/s/shard

### Activities
- [ ] CDK: provision Kinesis Data Stream (start `ON_DEMAND` to skip shard sizing math)
- [ ] MUST-KNOW: **Shards as the unit of throughput** — 1 MB/s in, 2 MB/s out per shard (shared). Partition key hashes to a shard.
- [ ] Producer Lambda emits synthetic SaaS events (e.g., `matter.created`, `user.login`) with `partitionKey=tenantId` for ordering per tenant
- [ ] MUST-KNOW: **Partition key choice** — same key always lands on same shard → ordered. Choose a key that's both well-distributed (avoid hot shards) AND where order matters (tenant id is usually right).
- [ ] CDK: wire Firehose to consume the stream → Iceberg table (re-using Unit 4 patterns)
- [ ] CDK: wire a second Lambda as a parallel consumer of the same stream (ESM)
- [ ] MUST-KNOW: **Multiple consumers** — KDS supports many consumers reading the same stream independently. Firehose is just another consumer. This is the core advantage over DDB Streams (which only feeds Lambda/Firehose, single fan-out).
- [ ] Register the second consumer with **enhanced fan-out** → compare latency/throughput vs shared
- [ ] MUST-KNOW: **EFO vs shared** — shared = 2 MB/s split across all consumers per shard. EFO = dedicated 2 MB/s/consumer/shard, push-based, lower latency. Costs more.
- [ ] Replay: stop consumers, push events, restart with `AT_TIMESTAMP` to a past time → verify the same events flow again
- [ ] MUST-KNOW: **Retention** — KDS keeps data 24h by default, up to 365d. Replay = your "rewind" button when a downstream bug needs reprocessing.

### Outcome
✅ **One Kinesis Data Stream, two independent consumers (Firehose + Lambda), demonstrated replay, demonstrated EFO.**

### What you'll know after Unit 5
- When KDS beats DDB Streams (multi-consumer, retention, replay)
- Shard math + partition key strategy
- ESM tuning (batch size, parallelization factor, on-failure destination)
- EFO economics

### Here we could also use X
- **Apache Kafka / MSK** — open-source standard, richer client ecosystem, harder to operate; pick if cross-cloud or extreme throughput
- **Amazon MSK Serverless** — Kafka without the ops, AWS-native
- **EventBridge** — for low-volume, schema-typed event routing (not a stream — it's pub/sub)
- **SNS + SQS fanout** — for simple decoupling without replay/ordering needs
- **Apache Pulsar** — multi-tenant streaming, growing in some shops

---

## Unit 6: Star Schema Modeling — "matters/firms/users → fact + dims, staging → intermediate → marts"

**Goal:** Take the raw CDC-landed Iceberg tables and model them into a Kimball star schema with a layered SQL pipeline, all in plain Athena SQL first (dbt comes next unit).

**New concepts:** OLTP vs OLAP, fact tables, dimension tables, surrogate keys, grain, conformed dimensions, SCD Type 1 vs Type 2, layered modeling (staging → intermediate → marts), denormalization tradeoffs.

### Key Patterns
- Staging: 1:1 with source, light cleanup (rename, cast types, deduplicate by primary key + max ts)
- Intermediate: joins, derived columns, business logic
- Marts: fact + dim tables; one row per business event (fact) or entity-version (dim)
- SCD2 dim: `valid_from`, `valid_to`, `is_current`, surrogate key separate from natural key

### Activities
- [ ] Sketch the star: what's the **grain** of `fct_matter_events`? (one row per matter state change, presumably)
- [ ] MUST-KNOW: **Grain** — the most important sentence in any fact table design: "one row per X." Get it wrong → either duplicate measures or lose detail.
- [ ] Identify dimensions: `dim_firm`, `dim_user`, `dim_date` (always have a date dim)
- [ ] MUST-KNOW: **Surrogate keys** — never use natural/business keys as PKs in dims. Surrogates let you SCD2 without breaking facts; insulate from upstream key changes.
- [ ] Write **staging** SQL views/tables in Athena: one per source DDB table, latest-version per id
- [ ] Write **intermediate** SQL joining staging to enrich (e.g., matter + firm)
- [ ] Write `dim_user` as SCD2 from CDC stream (track historical changes)
- [ ] MUST-KNOW: **SCD2 logic** — close out previous row (`valid_to = new.event_ts`, `is_current = false`), insert new row. Iceberg MoR makes this clean.
- [ ] Write `fct_matter_events` joining to dimension surrogate keys
- [ ] Verify: query "active matters per firm last week" → should be a clean GROUP BY against the star
- [ ] MUST-KNOW: **Why denormalize into dims** — BI tools and humans write better queries with `dim_user.region` than 5-table joins. Storage is cheap; query simplicity is not.

### Outcome
✅ **Star schema in Iceberg: 1 fact table + 3 dim tables (one as SCD2), populated via layered Athena SQL.**

### What you'll know after Unit 6
- How to pick a fact's grain
- SCD2 mechanics in an append-only world
- Why staging → intermediate → marts is the standard split
- The OLTP→OLAP shape change ("entity rows" → "events with measures + lookups")

### Here we could also use X
- **One Big Table (OBT)** — denormalize everything into one wide table; cheap on columnar engines, popular at smaller scale or for ML feature stores
- **Data Vault** — Inmon-school alternative; hubs/links/satellites; verbose but auditable, used in regulated industries
- **Activity Schema** — newer, single-stream-of-customer-actions model (Narrator); good for product analytics
- **Snowflake schema** (literal) — normalized dim subdimensions; rarely worth it nowadays

---

## Unit 7: QuickSight on Athena — "Connect a dashboard to the warehouse"

**Goal:** Build a QuickSight dashboard on top of the marts; understand SPICE vs direct query and scheduled refresh.

**New concepts:** QuickSight dataset vs analysis vs dashboard, SPICE (in-memory cache) vs direct query, IAM permissions for QS → Athena → S3, scheduled refresh, row-level security basics, parameter controls.

### Activities
- [ ] Grant QuickSight permissions to the Athena workgroup + S3 warehouse bucket (CDK or console)
- [ ] MUST-KNOW: **QS permission model** — QS uses its own service-linked IAM identity; granting access to your warehouse bucket and Glue catalog is a common forget.
- [ ] Create a Dataset on `fct_matter_events` joined with dims
- [ ] Build an analysis: matters per firm over time, top users by activity
- [ ] Switch dataset between SPICE and direct query — observe latency
- [ ] MUST-KNOW: **SPICE vs direct** — SPICE = in-memory, fast, freshness = last refresh. Direct = always live, slower, costs Athena $/scan per dashboard view. Use SPICE for exec dashboards, direct for ops tools.
- [ ] Configure scheduled refresh on SPICE dataset
- [ ] Publish as dashboard, share with another principal
- [ ] (Optional) Add a parameter control filtering by firm

### Outcome
✅ **Working QuickSight dashboard on the SaaS warehouse, refreshing on schedule.**

### What you'll know after Unit 7
- QS dataset/analysis/dashboard separation
- SPICE economics
- End-to-end IAM chain QS → Athena → Glue → S3

### Here we could also use X
- **Apache Superset** — open source BI, self-host
- **Metabase** — easier UX, popular at smaller orgs
- **Looker** — SQL semantic layer (LookML), Google-owned, Enterprise
- **Grafana** — better for ops/time-series than ad-hoc analytics
- **Streamlit / Hex / Observable** — for dev-built dashboards in Python/JS

---

## Unit 8: dbt Extension — "Re-do the modeling layer in dbt-core + dbt-athena"

**Goal:** Replace the hand-rolled SQL pipeline from Unit 6 with dbt models — getting tests, lineage, incremental builds, and the standard analytics-engineering workflow.

**New concepts:** dbt project structure (`models/`, `seeds/`, `tests/`, `macros/`), `ref()` and `source()`, materializations (view/table/incremental/ephemeral), `dbt-athena` adapter quirks (Iceberg support, S3 staging), tests (generic + singular), `dbt docs generate`, lineage graph, snapshots (dbt's SCD2).

### Key Patterns
- Project: `dbt init`, `profiles.yml` (Athena workgroup, S3 staging dir, region, AWS profile)
- `models/staging/stg_<source>.sql` w/ `{{ config(materialized='view') }}`
- `models/marts/fct_matter_events.sql` w/ `{{ config(materialized='incremental', incremental_strategy='merge', unique_key='event_id', table_type='iceberg') }}`
- Tests: `tests/generic/` + `schema.yml` declarations (`unique`, `not_null`, `relationships`)
- Snapshots for SCD2

### Activities
- [ ] Install dbt-core + dbt-athena
- [ ] MUST-KNOW: **What dbt is, in one line** — a SQL compiler that turns Jinja-templated SQL files into a DAG of `CREATE TABLE/VIEW` statements run against your warehouse.
- [ ] Configure `profiles.yml` for Athena
- [ ] Convert Unit 6's staging SQL → dbt staging models
- [ ] Convert intermediate + marts similarly, using `ref()` to chain
- [ ] MUST-KNOW: **`ref()` vs hardcoded names** — `ref()` builds the DAG and lets dbt sort run order automatically; never write raw `database.schema.table` references.
- [ ] Add tests to `schema.yml` (`unique` on dim PKs, `not_null` on FKs, `relationships` between fact and dim)
- [ ] Make `fct_matter_events` an `incremental` model with `merge` on Iceberg
- [ ] MUST-KNOW: **Incremental on Iceberg** — Iceberg's MERGE INTO + dbt's incremental strategy = warehouse-native UPSERTs. Without Iceberg you'd hack append + dedupe.
- [ ] Use a dbt snapshot for `dim_user` SCD2 → diff against your hand-rolled SCD2 from Unit 6
- [ ] Run `dbt docs generate` + `dbt docs serve` → explore lineage graph
- [ ] Re-point QuickSight at dbt-built tables → confirm dashboard still works

### Outcome
✅ **Same star schema as Unit 6, now built by dbt with tests + docs + lineage; QuickSight unchanged.**

### What you'll know after Unit 8
- Why dbt won the analytics-engineering category
- `ref()`/`source()`/macros mechanics
- Incremental + merge on Iceberg
- dbt snapshots for SCD2

### Here we could also use X
- **dbt Cloud** (managed dbt + scheduler + IDE)
- **dbt-spark / dbt-snowflake / dbt-bigquery** — same dbt, different warehouse
- **Generic templating w/ Jinja** — for non-SQL data tasks
- **Dataform** (Google) — dbt-alike inside BigQuery
- **Coalesce** — visual transformation tool, GUI-first

---

## Unit 9: SQLMesh Extension — "Re-do (parts of) the modeling in SQLMesh; compare to dbt"

**Goal:** Build the same pipeline in SQLMesh; experience virtual data environments, automatic incremental change categorization, column-level lineage. Form an opinion on when to pick dbt vs SQLMesh.

**Status note (Apr 2026):** dbt remains the industry default for hiring/job listings; SQLMesh has meaningful adoption growth especially at scale where dev-env cost + incremental safety hurt. Worth knowing both.

**New concepts:** SQLMesh project structure, **virtual environments** (zero-copy table swaps), incremental-by-default models, breaking-vs-non-breaking change categorization, plan/apply workflow, audits (vs dbt tests), column-level lineage, dbt-compat mode.

### Key Patterns
- `sqlmesh init` → `models/`, `audits/`, `tests/`, `macros/`, `config.yaml`
- Model header (Python-style): `MODEL (name fct_matter_events, kind INCREMENTAL_BY_TIME_RANGE (time_column event_ts), partitioned_by day(event_ts))`
- `sqlmesh plan dev` → creates a dev virtual env (table aliases pointing at materialized output)
- `sqlmesh plan prod` → promotes (zero-copy where possible)
- Audits: SQL queries that must return zero rows (declarative tests)

### Activities
- [ ] Install sqlmesh; init a project alongside the dbt project (or in a new dir)
- [ ] MUST-KNOW: **Virtual environments** — SQLMesh maintains schema-level "views" pointing at physical tables; `dev` and `prod` are aliases over the same materialized data when nothing changed → free dev branches.
- [ ] Migrate a couple of dbt models to SQLMesh syntax (it has a dbt-compat mode — try it)
- [ ] MUST-KNOW: **Incremental by default** — SQLMesh tracks high-watermarks and never silently full-refreshes; categorizes changes as breaking/non-breaking automatically.
- [ ] Make a non-breaking change (add a column) → run `plan` → observe SQLMesh classifies it correctly + reuses existing data
- [ ] Make a breaking change (alter logic of existing column) → observe SQLMesh requires a backfill plan
- [ ] Add audits → diff against dbt's `tests` mental model
- [ ] Inspect column-level lineage UI / output
- [ ] Form your own opinion: when would I pick SQLMesh? When would I stay on dbt?

### Outcome
✅ **A subset of the warehouse rebuilt in SQLMesh with a working dev-vs-prod virtual env workflow; written comparison notes in `learnings.md`.**

### What you'll know after Unit 9
- The SQLMesh execution model (plan/apply, virtual envs)
- Why SQLMesh's incrementalism is safer than dbt's
- Where dbt's ecosystem maturity still wins
- How to migrate models between the two

### Here we could also use X
- **dbt Mesh** (multi-project dbt) — dbt's answer to scale concerns
- **Lea (Carbonfact)** — newer minimalist SQL framework
- **Airflow + raw SQL** — no transformation framework at all (sometimes the right call for tiny stacks)

---

## Unit 10: Adjacent Tech Acknowledgement — "What else is out there"

**Goal:** Survey the broader data-warehousing / data-engineering landscape so you don't develop tunnel vision on the AWS+Iceberg+dbt+SQLMesh stack. Pick 1-2 tangents to learn next.

**Format:** No checkboxes for "build it" — this is a guided **read + discuss** unit. For each tech below, Claude explains:
1. What it is (one line)
2. What problem it solves that the chosen stack doesn't (or solves worse)
3. When you'd actually pick it
4. The "if you only know one thing" insight

### Cloud Warehouses (alternatives to "Athena on S3 + Iceberg")
- **Snowflake** — managed columnar warehouse; the OG cloud warehouse; multi-cluster compute, Time Travel built in, marketplace for data sharing
- **Google BigQuery** — serverless warehouse, separation of storage/compute taken to the extreme; flat-rate or per-TB-scanned billing
- **Databricks SQL Warehouse** — Delta Lake-native, lakehouse pattern; strong ML integration
- **ClickHouse** — open-source OLAP; fastest single-query engine for many workloads; self-host or ClickHouse Cloud
- **DuckDB Cloud / MotherDuck** — DuckDB-as-a-service, "small data warehouse" niche

### Streaming / Ingestion (alternatives to "DDB Streams + KDS + Firehose")
- **Apache Kafka / Confluent / MSK** — the open standard; richer ecosystem than KDS; pick if cross-cloud or extreme scale
- **Apache Flink / Kinesis Data Analytics for Flink (Managed Service for Apache Flink)** — stateful stream processing (windows, joins, CEP)
- **Apache Pulsar** — multi-tenant alternative to Kafka
- **Debezium** — open-source CDC connectors for relational DBs
- **Estuary Flow / Airbyte / Fivetran** — managed connectors; less code, more $$$
- **Materialize / RisingWave** — streaming SQL databases; incremental view maintenance

### Lakehouse Table Formats (alternatives to Iceberg)
- **Delta Lake** — Databricks-led; strong if you live in Databricks
- **Apache Hudi** — Uber-origin; strong CDC story; loses ground to Iceberg
- **Apache Paimon** — Flink-native lakehouse table format

### Transformation (alternatives to dbt/SQLMesh)
- **Apache Hamilton** — Python-native, function-as-DAG transformation; great for ML-heavy pipelines (this is what your "new kid" cousin might've been)
- **Dataform** — Google's dbt-alike inside BigQuery
- **Lea** — minimalist SQL framework
- **Coalesce** — GUI-first transformation
- **Pure Spark/PySpark** — no framework, just Spark jobs

### Orchestration (none used yet in this project — would be in real production)
- **Apache Airflow / MWAA** — the standard; Python DAGs; mature, sometimes painful
- **Dagster** — newer, asset-centric; great DX; growing fast
- **Prefect** — Python-native, dynamic
- **AWS Step Functions + EventBridge Scheduler** — AWS-native, no extra service to run
- **Temporal** — durable execution, beyond data engineering
- **Kestra** — declarative YAML workflows
- **Mage** — newer, notebook-friendly

### Catalog / Governance (you used Glue — others)
- **Unity Catalog** (Databricks) — going open-source 2024-25
- **Apache Polaris / Lakekeeper / Tabular** — open Iceberg REST catalogs
- **Apache Atlas / DataHub / OpenMetadata / Amundsen** — discovery + governance
- **Great Expectations / Soda / Elementary** — data quality monitoring (overlaps dbt tests/audits)

### BI (alternatives to QuickSight)
- **Tableau** — enterprise standard, expensive
- **Looker** — semantic layer (LookML), Google-owned
- **Apache Superset** — open source
- **Metabase** — easy UX, smaller-org default
- **Grafana** — ops/time-series
- **Hex / Observable / Streamlit** — code-first dashboards

### Activities
- [ ] Read through this list with Claude. For each row, ask "would this fit my SaaS pipeline better than what I built?" — get a yes/no/maybe + reason.
- [ ] Pick 1-2 to add to `to-learn.md` as concrete next-project candidates.
- [ ] Discuss: if your SaaS scale grew 100×, which of these become unavoidable?
- [ ] Discuss: if you joined a new team using one of these instead of your current stack, what's the smallest possible mental adjustment?

### Outcome
✅ **A grounded mental map of where AWS+Iceberg+dbt+SQLMesh fits in the wider ecosystem; 1-2 next learning candidates parked.**

### What you'll know after Unit 10
- The shape of the data tooling landscape, not just one slice of it
- Which adjacent techs are worth real time vs which are "good to recognize"
- Where AWS-native loses to OSS or other clouds, and vice versa

---

## What You'll Know After This Project

### Storage & Format
- ✅ Parquet internals (row groups, encodings, compression tradeoffs)
- ✅ Iceberg metadata anatomy + operations (snapshots, evolution, compaction, expiry)
- ✅ When to pick CoW vs MoR

### Ingestion
- ✅ DDB Streams shape + when it suffices
- ✅ Kinesis Data Streams shard math, partition keys, replay, EFO
- ✅ Firehose buffering, Parquet conversion, transform Lambda contract
- ✅ When to pick KDS over DDB Streams (multi-consumer, retention, replay)

### Query
- ✅ Athena workgroups + Glue catalog integration
- ✅ DuckDB local-dev workflow on S3 Iceberg
- ✅ Reading EXPLAIN; understanding column pruning + pushdown

### Modeling
- ✅ Star schema, grain, surrogate keys, SCD2
- ✅ Layered staging → intermediate → marts
- ✅ Same pipeline in raw SQL, dbt, and SQLMesh

### BI
- ✅ QuickSight dataset/analysis/dashboard, SPICE, scheduled refresh

### Infra
- ✅ AWS CDK (Python) for all the above

### Landscape
- ✅ Where Iceberg, dbt, SQLMesh, KDS sit relative to alternatives
- ✅ When AWS-native loses to OSS / other clouds

### Ready To
After this project, you can:
- ✅ Design and ship a real CDC-driven analytics pipeline on AWS
- ✅ Choose appropriate ingestion + table format + transformation tech for a given scale
- ✅ Read someone else's lakehouse stack and place each tool in context
- ✅ Decide whether to bring in dbt vs SQLMesh on a new project

---

## Teaching Instructions (for Claude)

**When resuming a session**:
1. Read "Session State" to identify current unit and next unchecked item
2. Locate next checkbox
3. Teach the concept/activity:
   - Start with mental model (1-2 sentences: what and why)
   - Show the essential demonstration (code, SQL, CLI command, metadata snippet, diagram)
   - Compare to user's existing AWS Lambda/DynamoDB/SAM experience when helpful (user is a backend Python dev new to data engineering)
   - Teach MUST-KNOWs just-in-time
   - Provide real-world example from the SaaS pipeline
4. Guide user through the activity:
   - Don't just list steps — walk through interactively
   - Let user write the code/SQL/CDK; review and critique
   - When user hits an obstacle, use it as a teaching moment
5. Verify:
   - **Code drills**: run pyarrow/pyiceberg/duckdb scripts, inspect output (file sizes, row counts, metadata)
   - **AWS drills**: `cdk deploy`, then verify with AWS CLI (`aws kinesis describe-stream`, `aws s3 ls`, `aws glue get-table`), Athena query, console screenshot
   - **SQL drills**: run in Athena/DuckDB, check result + EXPLAIN
   - **Concept checks**: ask user to explain the WHY of a choice; pose a "what if X changed" variation
   - **End-to-end**: data lands in S3 → Glue table sees it → Athena queries return → dashboard renders
6. Check the box when complete
7. Update "Session State"

**Cross-pollination cadence**:
After completing each unit's main activities, present that unit's "Here we could also use X" section as a brief discussion: name each alternative, what it'd swap for, when you'd actually pick it. Keep it conversational, ~3-5 minutes of discussion per unit. The dedicated Unit 10 is the deeper survey — per-unit callouts are the just-in-time version.

**Teaching style**:
- Short, direct explanations
- Mental model first, then demonstration
- MUST-KNOWs when relevant, not upfront
- Real examples from this SaaS pipeline (matters/firms/users), not toy examples
- Always tie new AWS service to user's existing AWS mental model (Lambda/DDB/API GW)
- Always name the tradeoff behind a choice — never present a default as obvious

**Verification protocol**:
- After every code/CDK change: build + deploy + verify with CLI/console — don't trust deploy-success alone
- After every Iceberg write: inspect metadata files in S3 + query the table
- After every modeling change (Unit 6+): query the resulting table + spot-check rows
- End of each unit: full end-to-end verification (data flows from source through pipeline to query/dashboard)

**Unit workflow**:
- Guide user through one goal per unit
- Teach concepts together in context, not isolation
- Going Deeper / "Here we could also use X" items are optional — offer but don't block
- Let user drive pace; CDK deploys can be slow, plan around it

**References**:
- Apache Iceberg: https://iceberg.apache.org/docs/latest/
- Apache Parquet: https://parquet.apache.org/docs/
- pyiceberg: https://py.iceberg.apache.org/
- pyarrow: https://arrow.apache.org/docs/python/
- DuckDB: https://duckdb.org/docs/
- AWS Athena: https://docs.aws.amazon.com/athena/
- AWS Kinesis: https://docs.aws.amazon.com/kinesis/
- AWS Glue: https://docs.aws.amazon.com/glue/
- AWS CDK Python: https://docs.aws.amazon.com/cdk/api/v2/python/
- dbt-athena: https://github.com/dbt-athena/dbt-athena
- SQLMesh: https://sqlmesh.readthedocs.io/

---

## Session State

**Current Unit:** Not started
**Current Step:** —
**Last Updated:** —
**Progress**: 0/10 units complete
