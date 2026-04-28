# Adjacent Tech — saas-warehouse

Standalone reference. Browse anytime via `/adjacent saas-warehouse` (or `/adjacent` from within the project).

The chosen stack for this project: **AWS CDK (Python) + DDB Streams / Kinesis Data Streams + Firehose + Iceberg/Parquet on S3 + Glue Catalog + Athena + dbt + SQLMesh + QuickSight**.

Each entry below: one line on what it is, when you'd actually pick it.

---

## Columnar Storage Formats (alternatives to Parquet)

- **Apache ORC** — Hive-era columnar format; still common in legacy Hadoop estates. Pick when joining a Hortonworks/Cloudera-rooted org.
- **Apache Avro** — row-based, schema-evolution-friendly. Pick for streaming payloads (Kafka, KDS records); not for analytics scans.
- **Apache Arrow IPC / Feather** — in-memory columnar format. Pick for cross-process zero-copy, not durable storage.

## DataFrame / Local Engines (alternatives to pyarrow + DuckDB)

- **Polars** — Rust-backed DataFrame, faster on single-node than pandas. Pick when you outgrow pandas but don't want a warehouse.
- **Pandas** — the default. Pick for quick scripting; bad at large data + columnar IO.
- **MotherDuck** — DuckDB-as-a-service. Pick for "warehouse for small data" without infra.

## Open Table Formats (alternatives to Iceberg)

- **Delta Lake** — Databricks-led; strong if you live in Databricks. Pick when org is on Databricks.
- **Apache Hudi** — Uber-origin, strong CDC merge story. Pick for heavy upsert workloads (loses ground to Iceberg post-2024).
- **Apache Paimon** — Flink-native lakehouse table format. Pick when Flink is your stream processor.
- **Hive ACID** — legacy; only relevant if inheriting an old Hive estate.

## Iceberg Catalogs (alternatives to AWS Glue Catalog)

- **Apache Polaris** (Snowflake-led, OSS) — vendor-neutral REST catalog.
- **Lakekeeper** — Rust-based Iceberg REST catalog.
- **Tabular** (acquired by Databricks 2024) — managed Iceberg catalog + automation.
- **Unity Catalog** — Databricks; going more open over time.
- Pick anything REST-based when multi-engine / multi-cloud portability matters.

## Cloud Warehouses (alternatives to "Athena on S3 + Iceberg")

- **Snowflake** — managed columnar warehouse; multi-cluster compute, Time Travel, marketplace. Pick for enterprise default + best-in-class UX.
- **Google BigQuery** — serverless warehouse, extreme separation of storage/compute. Pick on GCP or for ad-hoc-heavy analytics.
- **Databricks SQL Warehouse** — Delta-native; lakehouse pattern. Pick when ML + BI live together.
- **ClickHouse** — open-source OLAP; often the fastest single-query engine. Pick for real-time analytics, product event analytics.
- **StarRocks / Doris** — emerging OSS OLAP, Apache-licensed. Pick if you want ClickHouse-style perf with MySQL protocol.
- **Trino** (self-hosted) — Athena's open-source ancestor. Pick when you need Athena's flexibility but not its limits/billing model.

## Streaming / Ingestion (alternatives to DDB Streams + KDS + Firehose)

- **Apache Kafka / Confluent / MSK** — open standard, richer ecosystem. Pick for cross-cloud, extreme scale, or rich client tooling.
- **Apache Pulsar** — multi-tenant alt to Kafka. Pick for tenant isolation needs.
- **Apache Flink / Managed Service for Apache Flink** — stateful stream processing (windows, joins, CEP). Pick when KDS/Firehose isn't enough — you need real stream computation.
- **Kafka Streams** — JVM-only stream processing library. Pick on JVM + Kafka shop.
- **Debezium** — open-source CDC for relational DBs. Pick for RDS/Postgres/MySQL CDC.
- **AWS DMS** — managed migration / CDC. Pick for one-time migrations or simple ongoing CDC.
- **EventBridge Pipes** — managed source-to-target with filter/transform. Pick to avoid custom glue Lambdas.
- **EventBridge** — pub/sub event bus. Pick for low-volume schema-typed routing (not a stream).
- **Estuary Flow / Airbyte / Fivetran** — managed connectors. Pick to skip building ingestion entirely (pay $$$).
- **Materialize / RisingWave** — streaming SQL DBs with incremental view maintenance. Pick when you need always-fresh aggregates.

## Compute / Heavy Transforms (alternatives to Lambda + Athena)

- **AWS Glue Jobs (Spark)** — managed PySpark. Pick when transforms exceed Lambda limits or need Spark.
- **EMR Serverless / EMR on EKS** — Spark/Hive/Presto at scale.
- **Databricks Jobs** — Spark + notebooks + ML.
- **AWS Batch / ECS Tasks** — for long-running Python jobs without Spark.
- **DuckDB on Lambda / Fargate** — increasingly viable for mid-scale transforms; punches above its weight.

## Transformation Frameworks (alternatives to dbt / SQLMesh)

- **Apache Hamilton** — Python function-DAG. Pick for ML-heavy pipelines or when transforms aren't all SQL.
- **Dataform** — Google's dbt-alike inside BigQuery. Pick on BQ.
- **Lea (Carbonfact)** — minimalist SQL framework. Pick when dbt feels heavy.
- **Coalesce** — GUI-first transformation. Pick for analyst-led teams.
- **dbt Mesh** (multi-project dbt) — dbt's answer to large-scale dbt. Pick when one dbt project gets too big.
- **dbt Cloud** — managed dbt + scheduler + IDE. Pick to skip self-hosting + orchestration.
- **Pure Spark / PySpark scripts** — no framework. Pick for very small or very specialized stacks.

## Orchestration (your current stack uses none — these are real-prod options)

- **Apache Airflow / MWAA** — the standard. Pick for mature Python DAGs.
- **Dagster** — newer, asset-centric, great DX. Pick for new builds favoring software engineering rigor.
- **Prefect** — Python-native, dynamic. Pick when DAGs need runtime decisions.
- **AWS Step Functions + EventBridge Scheduler** — AWS-native. Pick for serverless-only shops avoiding new services.
- **Temporal** — durable execution beyond data eng. Pick for long-running stateful workflows that go beyond batch.
- **Kestra** — declarative YAML workflows. Pick for low-code / multi-language.
- **Mage** — notebook-friendly. Pick for analyst-friendly pipelines.

## Data Quality (alternatives to dbt tests / SQLMesh audits)

- **Great Expectations** — declarative expectations on data; mature.
- **Soda** — SQL-based quality checks; easier than GE.
- **Elementary** — dbt-native observability + tests.
- **Monte Carlo / Bigeye / Anomalo** — managed data observability. Pick when team doesn't want to operate quality tooling.

## Catalog / Discovery / Governance (Glue is your catalog; these are discovery layers)

- **DataHub** (LinkedIn-origin OSS) — most popular OSS discovery.
- **OpenMetadata** — newer OSS, growing fast.
- **Amundsen** (Lyft-origin) — older OSS.
- **Atlan / Select Star / Castor** — managed.
- **Unity Catalog** — Databricks; doubles as governance.
- Pick when org has 100+ tables and people can't find data.

## BI / Dashboarding (alternatives to QuickSight)

- **Tableau** — enterprise standard; expensive.
- **Looker** — semantic layer (LookML), Google-owned. Pick for governed self-serve.
- **Apache Superset** — open source. Pick for self-host BI.
- **Metabase** — easy UX. Pick for smaller org defaults.
- **Grafana** — ops/time-series. Pick for observability dashboards, not analytics.
- **Hex / Observable / Streamlit / Evidence.dev** — code-first dashboards. Pick for dev-built reports + notebooks-as-products.
- **Power BI** — Microsoft estate.
- **Lightdash** — Looker-alike on top of dbt. Pick if you live in dbt and want a semantic layer cheaply.

## IaC (alternatives to AWS CDK Python)

- **Terraform / OpenTofu** — multi-cloud HCL. Pick for multi-cloud or strong module ecosystem.
- **AWS SAM** — your previous tool. Pick for pure-serverless quick starts.
- **AWS CloudFormation** — raw YAML/JSON. Pick when team forbids new tools.
- **Pulumi** — IaC in any language; same idea as CDK but multi-cloud. Pick for TS/Go/Python multi-cloud.
- **CDKTF** — CDK syntax over Terraform. Pick when you want CDK ergonomics + Terraform engine.
- **SST** — IaC for full-stack TS apps (CDK-based). Pick for serverless web apps.

## Ingestion-Layer Managed Services (skip ALL the above with $$$)

- **Fivetran** — 500+ connectors, set-and-forget. Pick when team can't build ingestion.
- **Airbyte** — OSS or managed; lots of connectors. Pick for self-host alternative to Fivetran.
- **Stitch** (Talend) — older, simpler.
- **Estuary Flow** — newer, real-time + batch.
- **Hightouch / Census** — reverse ETL (warehouse → SaaS apps). Adjacent to ingestion but inverse direction.

---

## Quick "if you grow to" map

| If you grow to... | The thing that probably needs to change |
|---|---|
| 100M+ events/day | KDS → MSK (Kafka), Firehose → Flink for stateful processing |
| Multi-cloud | Iceberg + REST catalog, Terraform for IaC, dbt over CDK-Athena |
| Real-time analytics (sub-second freshness) | ClickHouse or Materialize alongside the warehouse |
| Heavy ML | Databricks or dedicated feature store + Hamilton |
| 100+ analysts | Looker or dbt + Lightdash for semantic layer; DataHub for discovery |
| Compliance / regulated | Data Vault modeling, Unity Catalog or DataHub for governance, audit trails everywhere |

## Quick "AWS-native loses to" map

| Weakness | What wins |
|---|---|
| KDS shard math + EFO costs | Kafka (MSK or self-host) |
| Athena per-scan billing on dashboards | Snowflake / BigQuery / ClickHouse |
| QuickSight UX | Tableau / Looker / Metabase |
| Glue catalog flexibility | Apache Polaris / Unity Catalog |
| Firehose's "buffering only" model | Flink for real stream processing |
