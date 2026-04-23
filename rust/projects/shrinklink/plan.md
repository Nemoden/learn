# Shrinklink — Learning Plan

**Primary Audience**: Claude (AI teaching assistant)
**Purpose**: Teaching script for building a production-style URL shortener API to learn axum, sqlx, tracing, tower middleware, newtype patterns, and performance profiling.

**How Claude Uses This File**:
1. **Resume teaching** — Read "Session State" to see current sprint and next unchecked item
2. **Teach systematically** — Follow checkboxes sequentially, teaching concepts just-in-time
3. **Track progress** — Check boxes as user completes tasks
4. **Guide implementation** — Walk user through steps interactively (don't just list them)
5. **Verify work** — Run `cargo check`, `cargo clippy`, `cargo test` after each step. Also `curl` endpoints for integration verification.

**How User Uses This File** (secondary):
- See what's coming next
- Track overall progress
- Reference MUST-KNOWs and key patterns
- Understand the sprint structure

**Teaching Approach**: Feature-driven sprints. Each sprint builds one working API capability, teaching only the Rust concepts needed for that feature. Proper tooling (cargo, clippy, tests) from day 1.

**Prerequisite**: Cachebox + Logpipe projects complete — learner knows ownership, borrowing, generics, traits, async/tokio, trait objects, error handling, serde, clap, modules, workspaces.

## Architecture Overview

```
POST /urls          → shorten a URL → { "short": "abc123", "url": "..." }
GET  /urls/:slug    → 301 redirect to original
GET  /urls/:slug/stats → click count, timestamps
DELETE /urls/:slug  → soft-delete

┌──────────────────────────────────────────────────────┐
│                    shrinklink                          │
│                                                       │
│  src/main.rs           startup, tracing init, router  │
│  src/config.rs         env/file config                │
│  src/db.rs             sqlx pool + queries            │
│  src/error.rs          API error → JSON responses     │
│  src/types/                                           │
│  ├── mod.rs                                           │
│  ├── slug.rs           Slug newtype + generation      │
│  └── url.rs            ValidUrl newtype               │
│  src/routes/                                          │
│  ├── mod.rs                                           │
│  ├── shorten.rs        POST /urls                     │
│  ├── redirect.rs       GET /urls/:slug                │
│  └── stats.rs          GET /urls/:slug/stats          │
│  src/middleware.rs      tower layers                   │
│                                                       │
│  migrations/           sqlx migrations                │
│  tests/api.rs          integration tests              │
│                                                       │
│  DB: PostgreSQL                                       │
│  Stack: axum + sqlx + tracing + tower                 │
└──────────────────────────────────────────────────────┘
```

**Core Features**: URL shortening, redirect, click tracking, structured logging, performance profiling
**Built with**: axum, sqlx, tokio, tracing, tower, serde, reqwest (for tests)

---

## Sprint 1: Basic API — "POST and Redirect"

**Goal:** A working API that shortens URLs and redirects. First real web service in Rust.

**New concepts:** axum (Router, handlers, extractors, State), sqlx (Postgres, migrations, compile-time query checking), tower::ServiceBuilder, application state sharing

### Key Patterns
```rust
// axum handler
async fn shorten(
    State(pool): State<PgPool>,
    Json(body): Json<ShortenRequest>,
) -> Result<Json<ShortenResponse>, AppError> { ... }

// axum router
let app = Router::new()
    .route("/urls", post(shorten))
    .route("/urls/:slug", get(redirect))
    .with_state(pool);

// sqlx query (compile-time checked!)
let row = sqlx::query_as!(Url, "SELECT * FROM urls WHERE slug = $1", slug)
    .fetch_optional(&pool)
    .await?;

// sqlx migration (migrations/001_urls.sql)
CREATE TABLE urls (
    id BIGSERIAL PRIMARY KEY,
    slug TEXT UNIQUE NOT NULL,
    original_url TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### Steps

- [ ] Run `cargo new shrinklink` inside `projects/shrinklink/`, add dependencies: `cargo add axum tokio --features full` + `cargo add sqlx --features runtime-tokio,postgres,macros` + `cargo add serde --features derive` + `cargo add serde_json`
- [ ] MUST-KNOW: axum architecture — axum is built on tower (middleware) + hyper (HTTP). A `Router` maps paths → handler functions. Handlers are async functions whose arguments are **extractors** — axum calls them by inspecting the function signature. `State(pool)` extracts shared state, `Json(body)` parses JSON body. This is the opposite of Python/Flask where you pull from `request` — axum pushes data into your function.
- [ ] Create `migrations/001_urls.sql` — define the `urls` table (id, slug, original_url, created_at)
- [ ] MUST-KNOW: sqlx migrations — `sqlx migrate run` applies SQL files in order. Unlike ORMs (Django, SQLAlchemy), sqlx is NOT an ORM — you write raw SQL, but sqlx checks your queries against the real DB schema **at compile time**. This catches SQL typos and type mismatches before runtime. Requires `DATABASE_URL` env var pointing to a running Postgres.
- [ ] Set up Postgres (local or Docker): `docker run -d --name shrinklink-db -e POSTGRES_PASSWORD=dev -e POSTGRES_DB=shrinklink -p 5432:5432 postgres:16`
- [ ] Create `.env` file with `DATABASE_URL=postgres://postgres:dev@localhost:5432/shrinklink`
- [ ] Run `sqlx migrate run` to apply migration
- [ ] MUST-KNOW: sqlx compile-time checking — `sqlx::query!()` and `sqlx::query_as!()` macros verify your SQL against the live DB at compile time. If you rename a column, the compiler catches it. Trade-off: needs a running DB to compile (or use `sqlx prepare` for offline mode).
- [ ] Define `ShortenRequest` (serde: url field) and `ShortenResponse` (slug, url) structs
- [ ] Implement `POST /urls` handler — generate random slug (6-char alphanumeric), insert into DB, return JSON response
- [ ] MUST-KNOW: axum extractors — the order matters. `State` must come first. Each extractor consumes part of the request. `Json<T>` consumes the body — you can only have one body extractor. If extraction fails, axum returns an appropriate error status automatically.
- [ ] Implement `GET /urls/:slug` handler — look up slug in DB, return 301 redirect using `axum::response::Redirect::permanent(url)`
- [ ] MUST-KNOW: axum path extractors — `Path(slug): Path<String>` extracts from the URL path. axum matches `:slug` in the route pattern to the `Path` extractor. Similar to Flask's `@app.route("/<slug>")`.
- [ ] Create `src/error.rs` — define `AppError` enum, implement `IntoResponse` for it so errors become JSON responses with proper status codes
- [ ] MUST-KNOW: axum error handling — handlers return `Result<T, E>` where both `T` and `E` implement `IntoResponse`. You implement `IntoResponse` for your error type to control the HTTP status code and body. This is axum's version of Flask's `@app.errorhandler`.
- [ ] Wire it all in `main.rs`: create pool → build router → `axum::serve` on port 3000
- [ ] Test manually: `curl -X POST localhost:3000/urls -H 'Content-Type: application/json' -d '{"url":"https://example.com"}'` then `curl -v localhost:3000/urls/<slug>`
- [ ] Write integration test in `tests/api.rs` — spin up the app, POST a URL, GET the slug, verify redirect
- [ ] MUST-KNOW: Testing axum — use `axum::Router` directly with `tower::ServiceExt` to send test requests without starting a real server. Or use `reqwest` against a spawned server. Both patterns are common.
- [ ] Clippy, fmt, all tests pass

### Going Deeper
- [ ] **Add `DELETE /urls/:slug`** — soft delete (add `deleted_at` column, filter in queries). Practice migration evolution.
- [ ] **Add slug collision handling** — retry with new slug if `INSERT` hits unique constraint. Practice sqlx error matching.

### Outcome
✅ **Working URL shortener API**: POST to shorten, GET to redirect, data in Postgres, compile-time checked SQL

### What you'll know after Sprint 1
- axum: Router, handlers, extractors (State, Json, Path), IntoResponse
- sqlx: migrations, compile-time query macros, PgPool
- Async web server setup with tokio
- axum error handling pattern
- Integration testing web APIs

---

## Sprint 2: Newtypes + Validation — "Types That Can't Be Wrong"

**Goal:** Replace raw `String` with validated newtypes. Make invalid states unrepresentable.

**New concepts:** newtype pattern, `TryFrom`/`From` traits, sealed traits for validation, `Deref` for ergonomic access, custom axum extractors, `#[serde(try_from)]`

### Key Patterns
```rust
// Newtype — wraps String, adds meaning + validation
pub struct Slug(String);

impl TryFrom<String> for Slug {
    type Error = SlugError;
    fn try_from(s: String) -> Result<Self, Self::Error> {
        if s.len() != 6 || !s.chars().all(|c| c.is_ascii_alphanumeric()) {
            return Err(SlugError::Invalid(s));
        }
        Ok(Slug(s))
    }
}

// Deref for ergonomic &str access
impl std::ops::Deref for Slug {
    type Target = str;
    fn deref(&self) -> &str { &self.0 }
}

// Sealed trait — prevents external impl
mod private { pub trait Sealed {} }
pub trait Validate: private::Sealed {
    fn validate(raw: &str) -> Result<(), ValidationError>;
}
impl private::Sealed for Slug {}
impl Validate for Slug { ... }

// Serde integration — validate on deserialization
#[derive(Deserialize)]
pub struct ShortenRequest {
    #[serde(try_from = "String")]
    pub url: ValidUrl,
}
```

### Steps

- [ ] Create `src/types/slug.rs` — define `pub struct Slug(String)` newtype
- [ ] MUST-KNOW: Newtype pattern — a single-field tuple struct that wraps an existing type. `Slug(String)` and `String` are different types to the compiler. You can't accidentally pass a URL where a slug is expected. Zero runtime cost — it's the same bytes in memory, just different type checking. Python equivalent: imagine if `UserId(int)` was enforced by the type checker, not just documentation.
- [ ] Implement `TryFrom<String> for Slug` — validate: 6 chars, ASCII alphanumeric only
- [ ] MUST-KNOW: `TryFrom` vs `From` — `From` is infallible conversion (always succeeds). `TryFrom` is fallible (can fail with an error). Use `TryFrom` when validation can reject the input. Implementing `From<A> for B` auto-gives you `A.into()` → `B`. Implementing `TryFrom<A> for B` auto-gives you `A.try_into()` → `Result<B, E>`.
- [ ] Implement `Deref<Target = str> for Slug` — so `&slug` auto-coerces to `&str`
- [ ] MUST-KNOW: `Deref` coercion — implementing `Deref` lets your newtype "act like" the inner type for reading. `&Slug` becomes `&str` automatically. This means you can pass `&slug` to any function expecting `&str`. Don't implement `DerefMut` for newtypes — that would let callers bypass your validation.
- [ ] Add `Slug::generate() -> Slug` — random 6-char slug, guaranteed valid by construction
- [ ] Create `src/types/url.rs` — define `pub struct ValidUrl(String)` newtype
- [ ] Implement `TryFrom<String> for ValidUrl` — validate URL format (starts with `http://` or `https://`, has a host). Use the `url` crate: `cargo add url`
- [ ] MUST-KNOW: Validation at the boundary — validate once when data enters your system (from HTTP request), then use the newtype everywhere internally. No re-validation needed. If you hold a `ValidUrl`, it's valid by construction. This is "parse, don't validate" — a core Rust idiom.
- [ ] Add serde integration: `#[serde(try_from = "String")]` on `ValidUrl` so deserialization validates automatically
- [ ] MUST-KNOW: `#[serde(try_from = "String")]` — tells serde to deserialize as `String` first, then call `TryFrom<String>`. If validation fails, deserialization fails with your error message. Incoming JSON is validated before your handler ever sees it.
- [ ] Define a sealed validation trait in `src/types/mod.rs`
- [ ] MUST-KNOW: Sealed traits — a trait that external code can't implement. Pattern: define a `private::Sealed` supertrait in a private module. Only types in your crate can implement `Sealed`, so only your types can implement the public trait. Use when: you want to guarantee all implementors are known and validated.
- [ ] Update `ShortenRequest` to use `ValidUrl` instead of `String`
- [ ] Update handlers to use `Slug` instead of `String` — update path extractor, DB queries
- [ ] Implement `sqlx::Type`, `sqlx::Encode`, `sqlx::Decode` for `Slug` (or use `#[sqlx(transparent)]`)
- [ ] MUST-KNOW: `#[sqlx(transparent)]` — tells sqlx your newtype wraps a type it already knows how to encode/decode (String → TEXT). No manual trait impl needed. Derive it: `#[derive(sqlx::Type)] #[sqlx(transparent)] pub struct Slug(String);`
- [ ] Update all tests to use newtypes. Verify type safety: try to pass a raw String where Slug is expected — compiler rejects it.
- [ ] Clippy, fmt, all tests pass

### Going Deeper
- [ ] **Add `Display` and `Debug` impls** — `Display` shows the inner value, `Debug` shows `Slug("abc123")`. Practice the distinction.
- [ ] **Implement custom axum `Path` extractor for Slug** — `Path(slug): Path<Slug>` that validates in the extractor layer. Uses `#[async_trait]` and `FromRequestParts`.
- [ ] **Add `ClickCount(u64)` newtype** — for Sprint 4's stats. Demonstrate newtypes for numeric types, implement `Add`, `Display`.

### Outcome
✅ **Invalid data can't enter the system** — raw strings replaced with `Slug` and `ValidUrl` newtypes, validated at deserialization boundary

### What you'll know after Sprint 2
- Newtype pattern and why it matters
- `TryFrom`/`From` for validated construction
- `Deref` coercion for ergonomic access
- Sealed traits to restrict implementations
- `#[serde(try_from)]` for validation-on-deserialize
- `#[sqlx(transparent)]` for newtype persistence
- "Parse, don't validate" philosophy

---

## Sprint 3: Observability — "See What Your API Does"

**Goal:** Structured logging and request tracing on every endpoint. Know what happened, when, and how long it took.

**New concepts:** `tracing` crate (spans, events, levels), `tracing-subscriber`, tower middleware layers, `#[instrument]`, request ID propagation, structured fields

### Key Patterns
```rust
// Structured event
tracing::info!(slug = %slug, "redirect requested");

// Instrument a function — auto-creates a span
#[tracing::instrument(skip(pool))]
async fn shorten(
    State(pool): State<PgPool>,
    Json(body): Json<ShortenRequest>,
) -> Result<Json<ShortenResponse>, AppError> { ... }

// Tower tracing layer
use tower_http::trace::TraceLayer;
let app = Router::new()
    .route(...)
    .layer(TraceLayer::new_for_http());

// Subscriber setup
tracing_subscriber::fmt()
    .with_env_filter("shrinklink=debug,tower_http=debug")
    .json()  // structured JSON output
    .init();
```

### Steps

- [ ] Add dependencies: `cargo add tracing tracing-subscriber --features env-filter` + `cargo add tower-http --features trace`
- [ ] MUST-KNOW: `tracing` vs `log` — `log` crate is simple string logging. `tracing` adds **spans** (structured contexts that track a unit of work) and **structured fields** (key-value data attached to events). In production Rust, `tracing` is the standard. Think of it as Python's `structlog` but built into the language ecosystem.
- [ ] Set up `tracing_subscriber` in `main.rs` — `fmt()` subscriber with env filter
- [ ] MUST-KNOW: Subscriber architecture — `tracing` emits events, a **subscriber** decides what to do with them. `tracing_subscriber::fmt` prints to stdout. In production, you might use `tracing-opentelemetry` to send to Jaeger/Datadog. You configure this once at startup, all code uses `tracing::info!()` etc.
- [ ] Add `#[tracing::instrument]` to all handler functions
- [ ] MUST-KNOW: `#[instrument]` — auto-creates a span named after the function. Arguments become span fields. Use `skip(pool)` to exclude non-Display types. Use `fields(slug = %slug)` to customize. Each span has enter/exit timing, so you get request duration for free.
- [ ] Add `TraceLayer::new_for_http()` from `tower-http` to the router
- [ ] MUST-KNOW: Tower middleware — axum is built on tower. Middleware wraps handlers: `request → middleware → handler → middleware → response`. `TraceLayer` logs every request/response with method, path, status, duration. You add layers with `.layer()`. Order matters: outermost layer runs first.
- [ ] Add structured fields to events: `tracing::info!(slug = %slug, url = %url, "url shortened")`
- [ ] MUST-KNOW: Structured fields — `tracing::info!(key = value, "message")` attaches typed data to the event. `%` formats with `Display`, `?` with `Debug`. These fields are machine-parseable — you can filter/query them in log aggregators. Much better than string interpolation: `info!("shortened {slug}")` loses structure.
- [ ] Add request ID middleware — generate UUID per request, attach to span
- [ ] MUST-KNOW: Request ID propagation — attach a unique ID to the root span. Every sub-span (DB query, validation) inherits it. When debugging, filter all logs by request ID to see the full trace. This is how production systems correlate logs across services.
- [ ] Add `tracing::warn!` and `tracing::error!` for error paths (invalid URL, slug not found, DB errors)
- [ ] Configure log levels via `RUST_LOG` env var: `RUST_LOG=shrinklink=debug,tower_http=info cargo run`
- [ ] MUST-KNOW: `EnvFilter` — `RUST_LOG=shrinklink=debug,sqlx=warn` controls verbosity per crate. In production: `info` default, `debug` for your crate during incidents. This is runtime-configurable — no recompile needed.
- [ ] Test: make requests, verify structured log output shows spans, timing, fields
- [ ] Clippy, fmt, all tests pass

### Going Deeper
- [ ] **Add JSON log output** — `.json()` on subscriber. Practice parsing structured logs with `jq`.
- [ ] **Add `tower-http::timeout::TimeoutLayer`** — set 5s request timeout. Observe timeout logs.
- [ ] **Add custom span fields** — attach user-agent, content-length to request span. Practice `tower` `MakeSpan` customization.

### Outcome
✅ **Every request traced**: method, path, status, duration, request ID, structured fields. `RUST_LOG` controls verbosity.

### What you'll know after Sprint 3
- `tracing` crate: spans, events, levels, structured fields
- `tracing-subscriber` setup and `EnvFilter`
- `#[instrument]` for automatic span creation
- Tower middleware concept and `TraceLayer`
- Request ID propagation pattern
- Production logging practices

---

## Sprint 4: Click Stats — "Track and Report"

**Goal:** Count clicks on each short URL. Report stats via API. Practice non-trivial DB queries.

**New concepts:** sqlx aggregations/joins, `sqlx::FromRow`, connection pool tuning, `UPDATE ... RETURNING`, database transactions, `chrono` for timestamps

### Key Patterns
```rust
// Track a click (atomic increment + return)
let url = sqlx::query_as!(UrlRow,
    "UPDATE urls SET click_count = click_count + 1, last_clicked_at = now()
     WHERE slug = $1 AND deleted_at IS NULL
     RETURNING *",
    slug.as_ref()
).fetch_optional(&pool).await?;

// Stats response
#[derive(Serialize)]
struct StatsResponse {
    slug: Slug,
    original_url: ValidUrl,
    click_count: i64,
    created_at: DateTime<Utc>,
    last_clicked_at: Option<DateTime<Utc>>,
}

// FromRow for custom mapping
#[derive(sqlx::FromRow)]
struct UrlRow {
    id: i64,
    slug: String,
    original_url: String,
    click_count: i64,
    created_at: DateTime<Utc>,
    last_clicked_at: Option<DateTime<Utc>>,
    deleted_at: Option<DateTime<Utc>>,
}
```

### Steps

- [ ] Add `chrono` crate: `cargo add chrono --features serde`
- [ ] Write migration `002_add_click_tracking.sql` — add `click_count BIGINT DEFAULT 0`, `last_clicked_at TIMESTAMPTZ`, `deleted_at TIMESTAMPTZ` columns
- [ ] Run `sqlx migrate run`
- [ ] MUST-KNOW: Migration evolution — real projects evolve schema over time. Each migration is additive: never modify a previous migration file. `ALTER TABLE ADD COLUMN` with defaults is safe for existing rows. This is the same pattern as Django/Alembic migrations.
- [ ] Define `UrlRow` struct with `#[derive(sqlx::FromRow)]`
- [ ] MUST-KNOW: `sqlx::FromRow` — maps DB rows to Rust structs by column name. Column `click_count BIGINT` maps to field `click_count: i64`. `Option<DateTime<Utc>>` for nullable columns. `query_as!` does compile-time checking; `query_as::<_, UrlRow>` does runtime mapping. Prefer `query_as!` when possible.
- [ ] Update redirect handler — increment `click_count` and set `last_clicked_at` on each redirect using `UPDATE ... RETURNING`
- [ ] MUST-KNOW: `UPDATE ... RETURNING` — Postgres-specific. Atomically updates and returns the modified row in one query. No race condition between UPDATE and SELECT. If two clicks happen simultaneously, both increment correctly because each is a single atomic statement.
- [ ] Implement `GET /urls/:slug/stats` handler — return click count, timestamps, original URL
- [ ] Add the stats route to the router
- [ ] MUST-KNOW: Connection pool tuning — `PgPoolOptions::new().max_connections(5)` controls how many DB connections are open. Too few → requests queue. Too many → DB overloaded. Default 10 is fine for dev. Production: tune based on DB `max_connections` ÷ number of app instances. Monitor with tracing spans on query duration.
- [ ] Add soft-delete: `DELETE /urls/:slug` sets `deleted_at = now()`, all queries filter `WHERE deleted_at IS NULL`
- [ ] MUST-KNOW: Soft delete — don't actually delete rows. Set a timestamp. Filter in queries. Allows recovery and audit trails. Trade-off: every query needs the filter. Some teams use DB views to hide this complexity.
- [ ] Write tests: shorten → redirect 3 times → check stats shows 3 clicks. Delete → verify redirect returns 404. Verify deleted URLs don't appear in stats.
- [ ] Add tracing spans to new handlers and DB queries
- [ ] Clippy, fmt, all tests pass

### Going Deeper
- [ ] **Add a `clicks` table** — separate click events with timestamp + user-agent for detailed analytics. Practice `INSERT` + `JOIN` + `GROUP BY`.
- [ ] **Add `GET /urls` — list all URLs** with pagination. Practice `LIMIT`/`OFFSET` with sqlx, return `Link` headers.
- [ ] **Add database transactions** — wrap shorten (check-then-insert) in a transaction. Practice `pool.begin()` + `tx.commit()`.

### Outcome
✅ **Click tracking works**: each redirect increments counter, `GET /urls/:slug/stats` returns analytics, soft-delete implemented

### What you'll know after Sprint 4
- sqlx: `FromRow`, `query_as!`, `UPDATE ... RETURNING`
- Migration evolution patterns
- Connection pool concepts and tuning
- Soft delete pattern
- `chrono` for timestamp handling
- Atomic DB operations

---

## Sprint 5: Performance — "Measure, Then Optimize"

**Goal:** Profile the redirect hot path. Find where time goes. Optimize with evidence.

**New concepts:** `cargo flamegraph`, criterion benchmarks, allocation awareness (Box vs stack), connection pool impact, tracing spans for performance measurement, `wrk`/`hey` load testing

### Key Patterns
```rust
// Criterion benchmark
use criterion::{criterion_group, criterion_main, Criterion};

fn bench_redirect(c: &mut Criterion) {
    let rt = tokio::runtime::Runtime::new().unwrap();
    c.bench_function("redirect_lookup", |b| {
        b.iter(|| rt.block_on(async {
            // ... actual DB lookup
        }))
    });
}

// Tracing spans for manual timing
let _span = tracing::info_span!("db_lookup", slug = %slug).entered();
let result = sqlx::query_as!(...).fetch_optional(&pool).await?;
drop(_span);  // span duration logged

// Stack vs heap awareness
let slug = Slug::try_from(s)?;     // stack — Slug is small (String is 24 bytes on stack + heap data)
let slugs: Vec<Slug> = ...;        // Vec on stack, elements on heap
let boxed: Box<dyn Sink> = ...;    // heap — dynamic dispatch needs indirection
```

### Steps

- [ ] Install load testing tool: `cargo install hey` (or use `wrk` / `ab`)
- [ ] Seed the DB with 1000 URLs using a script or test helper
- [ ] Run baseline load test: `hey -n 10000 -c 50 http://localhost:3000/urls/<slug>` — record p50, p95, p99 latency, requests/sec
- [ ] MUST-KNOW: Load testing basics — `-n 10000` total requests, `-c 50` concurrent. Look at p99 (worst 1%) not average. Average hides tail latency. If p50=2ms but p99=200ms, you have a problem the average won't show.
- [ ] Add tracing spans around DB query, slug validation, redirect response — identify where time goes
- [ ] MUST-KNOW: Span-based profiling — each `tracing::info_span!` records duration. With `tracing-subscriber`'s `fmt` layer, you see timing per span. This is lightweight profiling without external tools. For deeper analysis, use `tracing-flame` to generate flamegraphs from spans.
- [ ] Install and run `cargo flamegraph` on the server under load
- [ ] MUST-KNOW: Flamegraphs — visualize where CPU time is spent. Wide bars = hot functions. Read bottom-to-top: bottom is `main()`, top is leaf functions. Look for unexpected width — that's your bottleneck. Common findings: serialization, allocation, DNS resolution, TLS handshake.
- [ ] Analyze: is time spent in DB query? Serialization? Allocation? Connection pool wait?
- [ ] MUST-KNOW: Stack vs heap — `String`, `Vec`, `Box` allocate on heap. `i64`, `bool`, small structs are stack-only. Each heap allocation calls the allocator (~20-50ns). In a hot loop, unnecessary allocations compound. Your newtypes (Slug, ValidUrl) are zero-cost at runtime — they're just Strings underneath.
- [ ] Experiment: tune pool size — try `max_connections` at 2, 5, 10, 20. Re-run load test. Graph the results.
- [ ] MUST-KNOW: Pool size impact — too few connections → requests wait for a free connection (contention). Too many → Postgres context-switches between connections (overhead). Sweet spot depends on: query complexity, server CPU cores, Postgres config. Rule of thumb: `connections = (2 * cpu_cores) + disk_spindles`.
- [ ] Add `criterion` benchmarks: `cargo add criterion --dev`, create `benches/redirect.rs`
- [ ] Write benchmark: measure redirect handler latency in isolation (with test DB)
- [ ] MUST-KNOW: Criterion — statistical benchmarking. Runs your function many times, reports mean ± confidence interval, detects regressions between runs. Use `cargo bench` to run. Results in `target/criterion/`. Much more reliable than manual timing.
- [ ] Try one optimization based on findings (e.g., prepared statements, response caching, connection pool tuning) — re-run benchmarks to verify improvement
- [ ] Document findings: what was the bottleneck? What helped? What didn't?
- [ ] Clippy, fmt, all tests + benchmarks pass

### Going Deeper
- [ ] **Add `tracing-flame`** — generate flamegraphs directly from tracing spans. Compare with `cargo flamegraph` output.
- [ ] **Profile memory allocations** — use `dhat` or `jemalloc` stats to count allocations per request. Target: minimize allocations in redirect hot path.
- [ ] **Add response caching** — cache redirect targets in-memory for popular slugs. Measure hit rate and latency improvement. Practice `Arc<RwLock<HashMap>>` or `moka` crate.

### Outcome
✅ **Evidence-based optimization**: baseline measured, bottleneck identified with flamegraphs, improvement verified with criterion benchmarks

### What you'll know after Sprint 5
- Load testing (hey/wrk) and reading p50/p95/p99
- Flamegraph generation and interpretation
- Criterion benchmarking for microbenchmarks
- Stack vs heap allocation awareness
- Connection pool tuning methodology
- Span-based profiling with tracing

---

## Sprint 6: Hardening (Optional) — "Production-Ready"

**Goal:** Add production features: rate limiting, graceful shutdown, environment config.

**New concepts:** tower rate-limit layer, `tokio::signal` for shutdown, `config` crate for layered configuration, `tower::ServiceBuilder` for composing middleware

### Key Patterns
```rust
// Layered config
let config = Config::builder()
    .add_source(config::File::with_name("config/default"))
    .add_source(config::Environment::with_prefix("SHRINKLINK"))
    .build()?;

// Graceful shutdown
let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await?;
axum::serve(listener, app)
    .with_graceful_shutdown(shutdown_signal())
    .await?;

async fn shutdown_signal() {
    tokio::signal::ctrl_c().await.ok();
    tracing::info!("shutdown signal received");
}

// Composing middleware layers
let app = Router::new()
    .route(...)
    .layer(
        ServiceBuilder::new()
            .layer(TraceLayer::new_for_http())
            .layer(TimeoutLayer::new(Duration::from_secs(10)))
            .layer(CorsLayer::permissive())
    );
```

### Steps

- [ ] Add `config` crate: `cargo add config`
- [ ] Create `config/default.toml` — port, database URL, pool size, log level
- [ ] MUST-KNOW: Layered config — `config` crate merges from multiple sources in order: file defaults → environment vars → CLI args. Environment vars override file. `SHRINKLINK_PORT=8080` overrides `port = 3000` in TOML. This is 12-factor app style. Similar to Python's `pydantic-settings`.
- [ ] Implement `Config` struct, load in main, pass to app
- [ ] Add graceful shutdown with `tokio::signal::ctrl_c()`
- [ ] MUST-KNOW: Graceful shutdown — when Ctrl+C arrives, stop accepting new connections but finish in-flight requests. `axum::serve().with_graceful_shutdown()` handles this. Without it, mid-request connections get RST. In production, this is critical for zero-downtime deploys.
- [ ] Add CORS layer with `tower-http`: `cargo add tower-http --features cors`
- [ ] Add request timeout layer — 10s max per request
- [ ] MUST-KNOW: `ServiceBuilder` — composes multiple tower layers into one. Order matters: layers are applied inside-out. `ServiceBuilder::new().layer(A).layer(B)` means B wraps A wraps handler. Request flow: B → A → handler → A → B. Put tracing outermost (first in builder) so it captures everything.
- [ ] Add rate limiting — use `tower::limit::RateLimitLayer` or `governor` crate
- [ ] Write integration test: verify rate limiting returns 429, verify timeout returns 408
- [ ] Clippy, fmt, all tests pass

### Going Deeper
- [ ] **Add health check endpoint** — `GET /health` returns 200 + DB connectivity status. Standard for Kubernetes liveness/readiness probes.
- [ ] **Add OpenAPI spec** — use `utoipa` crate to auto-generate OpenAPI from your handlers. Practice derive macros for API documentation.
- [ ] **Dockerize** — multi-stage Dockerfile for minimal image. Practice `cargo build --release` in Docker.

### Outcome
✅ **Production-hardened**: env-based config, graceful shutdown, CORS, rate limiting, timeouts — ready for deployment

### What you'll know after Sprint 6
- Layered configuration (file + env)
- Graceful shutdown pattern
- Tower middleware composition
- Rate limiting and timeout patterns
- Production deployment considerations

---

## What You'll Know After This Project

### Web Stack (axum)
- ✅ Router, handlers, extractors (State, Json, Path, Query)
- ✅ `IntoResponse` for error handling
- ✅ Tower middleware: tracing, timeout, CORS, rate limiting
- ✅ `ServiceBuilder` for middleware composition
- ✅ Integration testing with axum

### Database (sqlx)
- ✅ Compile-time checked SQL queries
- ✅ Migrations, schema evolution
- ✅ `FromRow`, `query_as!`, `UPDATE ... RETURNING`
- ✅ Connection pool management and tuning
- ✅ Newtype ↔ DB column mapping with `#[sqlx(transparent)]`

### Observability (tracing)
- ✅ Structured logging with spans and events
- ✅ `#[instrument]` for automatic span creation
- ✅ Request ID propagation
- ✅ `EnvFilter` for per-crate log levels
- ✅ Span-based performance profiling

### Advanced Type Patterns
- ✅ Newtype pattern for domain types
- ✅ `TryFrom`/`From` for validated construction
- ✅ Sealed traits to restrict implementations
- ✅ `Deref` coercion for ergonomic access
- ✅ "Parse, don't validate" philosophy

### Performance
- ✅ Load testing and reading latency percentiles
- ✅ Flamegraph generation and interpretation
- ✅ Criterion microbenchmarks
- ✅ Stack vs heap allocation awareness
- ✅ Evidence-based optimization methodology

### Production Patterns
- ✅ Layered configuration (file + env)
- ✅ Graceful shutdown
- ✅ Middleware composition
- ✅ Soft delete, migration evolution
- ✅ Rate limiting and timeouts

### Career-Ready
After all three projects (cachebox + logpipe + shrinklink), you can:
- ✅ **Read and write idiomatic Rust** — ownership, traits, async, error handling are second nature
- ✅ **Build production web APIs** — axum, sqlx, tracing, tower
- ✅ **Design type-safe systems** — newtypes, sealed traits, validated construction
- ✅ **Profile and optimize** — flamegraphs, benchmarks, pool tuning
- ✅ **Join any Rust team** — practical experience across the full stack

---

## Teaching Instructions (for Claude)

**When resuming a session**:
1. Read "Session State" to identify current sprint and next unchecked item
2. Locate next checkbox in current sprint
3. Teach the concept/step:
   - Start with mental model (1-2 sentences: what it is, why it exists)
   - Show essential Rust code
   - Compare to Python equivalent when it helps (but be clear where Rust differs fundamentally)
   - Bridge from cachebox/logpipe: "in logpipe you used async with tokio, here we're using it for HTTP handlers"
   - Teach MUST-KNOWs just-in-time (when user encounters the need)
   - Provide real-world example from shrinklink project
4. Guide user through implementation:
   - Don't just list steps — walk through them interactively
   - Let user write the code, then review it
   - Answer questions as they arise
   - When user hits a compiler error, use it as a teaching moment
5. Verify user's work:
   - `cargo check` — does it compile?
   - `cargo clippy` — is it idiomatic?
   - `cargo test` — do tests pass?
   - `curl` endpoints — does the API work?
6. Check the box when user completes the task
7. Update "Session State" with progress

**Teaching style**:
- Short, direct explanations (no essays)
- Mental model first, then code
- MUST-KNOWs when relevant, not upfront
- Real examples from shrinklink, not toy examples
- Bridge from cachebox/logpipe knowledge where relevant
- Explain what bug the compiler prevents, not just "the compiler won't let you"
- Compare to Python/Flask/FastAPI equivalents when helpful

**Verification protocol**:
- After every code change: `cargo check` (compilation)
- After every sprint step: `cargo clippy` (idiomatic check)
- After every handler: `curl` to test (manual integration)
- After every sprint: `cargo test` (all tests pass)
- End of each sprint: review full code for quality

**Sprint workflow**:
- Guide user to build one API capability per sprint
- Teach concepts together in context (not in isolation)
- Have user run `cargo check/clippy/test` after each step
- Going Deeper items are optional — offer them but don't block progress
- Ensure Postgres is running before DB-related steps

**References**:
- Rust Book: https://doc.rust-lang.org/book/
- std docs: https://doc.rust-lang.org/std/
- axum docs: https://docs.rs/axum/latest/
- sqlx docs: https://docs.rs/sqlx/latest/
- tracing docs: https://docs.rs/tracing/latest/
- tower docs: https://docs.rs/tower/latest/
- tower-http docs: https://docs.rs/tower-http/latest/
- tokio tutorial: https://tokio.rs/tokio/tutorial
- Crate docs: https://docs.rs/{crate}/latest/

---

## Session State

**Current Sprint:** Not started
**Current Step:** —
**Last Updated:** —
**Progress**: 0/5 sprints complete (+ 1 bonus)
