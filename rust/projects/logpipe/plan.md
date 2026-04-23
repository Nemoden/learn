# Logpipe — Learning Plan

**Primary Audience**: Claude (AI teaching assistant)
**Purpose**: Teaching script for building a minimal log/stream processor (Source → Transform → Sink pipeline) to learn async Rust, trait design, lifetimes, dynamic dispatch, and workspaces.

**How Claude Uses This File**:
1. **Resume teaching** — Read "Session State" to see current sprint and next unchecked item
2. **Teach systematically** — Follow checkboxes sequentially, teaching concepts just-in-time
3. **Track progress** — Check boxes as user completes tasks
4. **Guide implementation** — Walk user through steps interactively (don't just list them)
5. **Verify work** — Run `cargo check`, `cargo clippy`, `cargo test` after each step

**How User Uses This File** (secondary):
- See what's coming next
- Track overall progress
- Reference MUST-KNOWs and key patterns
- Understand the sprint structure

**Teaching Approach**: Feature-driven sprints. Each sprint builds one working pipeline capability, teaching only the Rust concepts needed for that feature. Proper tooling (cargo, clippy, tests) from day 1.

**Prerequisite**: Cachebox project complete — learner knows ownership, borrowing, generics, Result<T,E>, serde, clap, modules, basic trait usage.

## Architecture Overview

```
Source → Transform → Transform → ... → Sink
(stdin/file)  (filter)    (parse)       (stdout/file/http)

┌─────────────────────────────────────────────────────────────┐
│                      logpipe workspace                       │
│                                                              │
│  logpipe-core/src/lib.rs  (pub trait Source, Transform, Sink)│
│  ├── source/                                                 │
│  │   ├── stdin.rs         StdinSource (sync)                 │
│  │   ├── file.rs          FileSource (sync line reader)      │
│  │   └── tail.rs          TailSource (async, like tail -f)   │
│  ├── transform/                                              │
│  │   ├── grep.rs          GrepTransform (regex filter)       │
│  │   ├── json_parse.rs    JsonParseTransform (extract fields)│
│  │   └── regex.rs         RegexTransform (field extraction)  │
│  ├── sink/                                                   │
│  │   ├── stdout.rs        StdoutSink                         │
│  │   ├── file.rs          FileSink                           │
│  │   └── http.rs          HttpSink (POST lines via reqwest)  │
│  └── pipeline.rs          Pipeline runner (sync + async)     │
│                                                              │
│  logpipe-cli/src/main.rs  (clap CLI, wires pipeline)        │
│                                                              │
│  Config: pipeline.toml (TOML pipeline definition)            │
└─────────────────────────────────────────────────────────────┘

CLI flow:  logpipe --source stdin --transform 'grep:ERROR' --sink stdout
           logpipe --config pipeline.toml
```

**Core Features**: Stdin/file/tail sources, grep/json/regex transforms, stdout/file/http sinks, sync + async modes, TOML config
**Built with**: tokio, clap, regex, serde + serde_json, toml, reqwest

---

## Sprint 1: Sync Pipeline — "stdin | grep | stdout"

**Goal:** Design the core traits (Source, Transform, Sink) from scratch and build a working sync pipeline that reads stdin, filters lines, and writes to stdout.

**New concepts:** trait design from scratch, custom Iterator impl, trait default methods, `impl Trait` in function signatures, `Box<dyn Error>`

### Key Patterns
```rust
trait Source {
    fn read_line(&mut self) -> Option<String>;
}

trait Transform {
    fn apply(&self, line: &str) -> Option<String>;
    // None = filter out this line
}

trait Sink {
    fn write_line(&mut self, line: &str) -> Result<(), Box<dyn std::error::Error>>;
    fn flush(&mut self) -> Result<(), Box<dyn std::error::Error>>;
}

// Running a pipeline (pseudo):
while let Some(line) = source.read_line() {
    let result = transforms.iter().try_fold(line, |l, t| t.apply(&l));
    if let Some(output) = result { sink.write_line(&output)?; }
}
```

### Steps

- [ ] Create project: `cargo new logpipe` inside `projects/logpipe/` — single crate for now, workspace comes in Sprint 5
- [ ] Define `trait Source` with `fn read_line(&mut self) -> Option<String>` in `src/source/mod.rs`
- [ ] MUST-KNOW: Trait design — traits are Rust's interfaces. Unlike cachebox where you used existing traits (Clone, Display, Serialize), here you design traits from scratch. Key decision: what methods? What's `&self` vs `&mut self`? What's the return type?
- [ ] Define `trait Transform` with `fn apply(&self, line: &str) -> Option<String>` in `src/transform/mod.rs`
- [ ] MUST-KNOW: Why `&self` not `&mut self` for Transform? Transforms are pure functions — they don't hold mutable state. This makes them shareable and composable. If a transform needs state later (e.g., counting), we'll revisit.
- [ ] Define `trait Sink` with `fn write_line(&mut self, line: &str) -> Result<()>` and `fn flush(&mut self) -> Result<()>` in `src/sink/mod.rs`
- [ ] Define a `PipeError` enum (using thiserror) in `src/error.rs` — start with `Io(#[from] io::Error)` variant
- [ ] Implement `StdinSource` — wraps `io::BufReader<io::Stdin>`, implements `Source`
- [ ] MUST-KNOW: `io::BufReader` — buffered reads are essential for line-by-line processing. `BufRead::lines()` returns an iterator of `Result<String>`. Without buffering, each `read` syscall reads one byte.
- [ ] Implement `GrepTransform` — holds a pattern string, `apply()` returns `Some(line)` if line contains pattern, `None` otherwise
- [ ] Implement `StdoutSink` — wraps `io::Stdout`, implements `Sink`
- [ ] Write `fn run_pipeline(source, transforms, sink)` — the core loop: read → apply transforms → write
- [ ] MUST-KNOW: `try_fold` for transform chains — `transforms.iter().try_fold(line, |l, t| t.apply(&l))` applies each transform, short-circuiting on `None`. This is cleaner than a manual loop. `try_fold` is `fold` that can bail early.
- [ ] Wire it up in `main.rs` — hardcoded for now: stdin | grep "ERROR" | stdout
- [ ] Test manually: `echo -e "ERROR: bad\nINFO: ok\nERROR: worse" | cargo run`
- [ ] Write unit tests for `GrepTransform::apply()` — test match, no-match, empty line, case sensitivity
- [ ] Clippy, fmt, all tests pass

### Going Deeper
- [ ] **Add `--invert` flag to GrepTransform** — like `grep -v`, filter out matching lines. Practice adding config to a transform.
- [ ] **Implement `Iterator` for Source** — make `StdinSource` implement `Iterator<Item = String>` so you can use `.filter().map()` chains directly

### Outcome
✅ **Working pipeline: `echo "..." | logpipe` filters lines containing a pattern** — you designed three traits from scratch and wired them together

### What you'll know after Sprint 1
- How to design traits (method signatures, `&self` vs `&mut self`, return types)
- Custom trait implementations
- `io::BufReader` and `BufRead` for line-by-line I/O
- `try_fold` for composing fallible chains
- When to use `Option<String>` as "keep or discard" signal

---

## Sprint 2: File Source + Multiple Transforms — "file | json_parse | grep | stdout"

**Goal:** Read from files, parse JSON lines, extract fields with regex. Composable multi-transform pipeline.

**New concepts:** lifetime annotations (`'a`), borrowed data in pipeline stages, `io::BufRead` trait, `serde_json::Value`, regex crate, when to own vs borrow

### Key Patterns
```rust
// Lifetime: source borrows a file handle
struct FileSource<R: BufRead> {
    reader: R,
}
// or own the file:
struct FileSource {
    reader: BufReader<File>,
}

// JSON field extraction
let v: serde_json::Value = serde_json::from_str(line)?;
v["field"].as_str()  // → Option<&str>

// Regex capture
let re = Regex::new(r"(\d{4}-\d{2}-\d{2})")?;
re.captures(line).and_then(|c| c.get(1)).map(|m| m.as_str())
```

### Steps

- [ ] Implement `FileSource` — reads a file line-by-line using `BufReader<File>`
- [ ] MUST-KNOW: Ownership decision — should `FileSource` own the `File` or borrow it? Own it. Owning is simpler, and sources are long-lived. Borrowing would force lifetime annotations on the pipeline. This is a key design decision: **own when the struct's lifetime matches the resource's lifetime**.
- [ ] Add `regex` crate: `cargo add regex`
- [ ] Upgrade `GrepTransform` to use `regex::Regex` instead of string contains
- [ ] MUST-KNOW: `regex::Regex` — compile once, match many. `Regex::new()` returns `Result` because the pattern might be invalid. Store the compiled regex in the struct, not the pattern string.
- [ ] Add `serde_json` crate (already know serde from cachebox)
- [ ] Implement `JsonParseTransform` — parses each line as JSON, extracts a specified field, returns it as a string
- [ ] MUST-KNOW: `serde_json::Value` — dynamic JSON. Unlike cachebox where you deserialized into known structs, here each line could be any JSON. `Value` is Rust's `Any`-like for JSON. Access fields with `value["key"]` or `.get("key")`.
- [ ] Implement `RegexTransform` — extracts a capture group from each line using a regex pattern
- [ ] Test composable pipeline: file | json_parse(field="message") | grep("ERROR") | stdout
- [ ] MUST-KNOW: Lifetime annotations intro — you might not need them yet (owned Strings flow through), but understand the question: when `apply()` takes `&str` and returns `Option<String>`, it creates a new owned String each time. This is simple but allocates. Sprint 3 will explore the borrow alternative.
- [ ] Write unit tests for each transform: JsonParseTransform with valid/invalid JSON, RegexTransform with match/no-match/multiple captures
- [ ] Write integration test: create a temp JSON-lines file → run pipeline → verify output
- [ ] Clippy, fmt, all tests pass

### Going Deeper
- [ ] **Chain 3+ transforms in a test** — verify order matters: `json_parse | grep` vs `grep | json_parse` produce different results
- [ ] **Add `JsonParseTransform` field path** — support nested fields like `"request.method"` using `serde_json::Value` navigation
- [ ] **Benchmark: owned String vs Cow** — measure allocation overhead of cloning every line through transforms

### Outcome
✅ **Multi-source, multi-transform pipeline**: `logpipe --source file:access.log --transform json_parse:message --transform grep:ERROR --sink stdout`

### What you'll know after Sprint 2
- When to own vs borrow in struct design
- `regex::Regex` compilation and capture groups
- `serde_json::Value` for dynamic JSON
- Composing multiple transforms in order
- Integration testing with temp files

---

## Sprint 3: Pluggable Sinks — "Box<dyn Sink>"

**Goal:** Multiple sink types selected at runtime. First real use of trait objects and dynamic dispatch.

**New concepts:** trait objects (`Box<dyn Trait>`), dynamic vs static dispatch, object safety rules, `dyn` vs generics tradeoffs, `Send` marker (prep for async)

### Key Patterns
```rust
// Static dispatch (monomorphized — fast, but type known at compile time)
fn run<S: Sink>(sink: &mut S, line: &str) { sink.write_line(line); }

// Dynamic dispatch (vtable — flexible, type chosen at runtime)
fn run(sink: &mut dyn Sink, line: &str) { sink.write_line(line); }
// or boxed:
fn run(sink: &mut Box<dyn Sink>, line: &str) { sink.write_line(line); }

// Creating trait objects
let sink: Box<dyn Sink> = match config.sink_type {
    "stdout" => Box::new(StdoutSink::new()),
    "file"   => Box::new(FileSink::new(path)?),
    "http"   => Box::new(HttpSink::new(url)),
};
```

### Steps

- [ ] Implement `FileSink` — writes lines to a file, one per line
- [ ] Add `reqwest` crate (blocking client for now): `cargo add reqwest --features blocking`
- [ ] Implement `HttpSink` — POSTs each line to a URL using `reqwest::blocking::Client`
- [ ] MUST-KNOW: Trait objects (`dyn Trait`) — in cachebox, generics were enough because types were known at compile time. Here, the user picks "stdout" or "file" or "http" at runtime via CLI flag. The compiler can't monomorphize — you need a vtable. `Box<dyn Sink>` is a fat pointer: data pointer + vtable pointer.
- [ ] Refactor `run_pipeline` to accept `&mut dyn Sink` (or `Box<dyn Sink>`) instead of a generic `S: Sink`
- [ ] MUST-KNOW: Object safety — not all traits can be `dyn`. Rules: no `Self` in return position, no generic methods, no `Sized` bound. Your Sink trait is safe because methods take `&mut self` and return concrete types.
- [ ] MUST-KNOW: `dyn` vs generics tradeoff — generics = zero-cost, but each type creates a new copy of the function (code bloat, compile time). `dyn` = one function, vtable indirection (~1ns overhead per call). For a pipeline processing millions of lines, this overhead is negligible. Use `dyn` when types are runtime-selected.
- [ ] Also refactor Source to `Box<dyn Source>` — full dynamic pipeline
- [ ] Add runtime selection: match on CLI arg string → create appropriate `Box<dyn Source>` and `Box<dyn Sink>`
- [ ] Add `--source` and `--sink` CLI flags with clap (already know clap from cachebox)
- [ ] MUST-KNOW: `Box<dyn Trait>` vs `&dyn Trait` — Box owns the trait object (lives as long as the Box). `&dyn Trait` borrows it (lifetime of the reference). Pipeline owns its components → use Box.
- [ ] Write tests: run same pipeline with each sink type, verify output
- [ ] Test HttpSink with a simple echo server or mock (discuss testing strategies for network-dependent code)
- [ ] Clippy, fmt, all tests pass

### Going Deeper
- [ ] **Implement `Sink` for `Vec<String>`** — a "collect" sink for testing. Demonstrates that traits can be implemented for any type, even std types you own via newtype.
- [ ] **Add `MultiplexSink`** — writes to multiple sinks at once. Takes `Vec<Box<dyn Sink>>`. This exercises nested trait objects.
- [ ] **Measure static vs dynamic dispatch** — write a benchmark comparing `fn run<S: Sink>(s: S)` vs `fn run(s: &mut dyn Sink)`. See that the difference is negligible for I/O-bound work.

### Outcome
✅ **`logpipe --sink file:output.log` or `--sink http:http://localhost:8080` or `--sink stdout`** — sink chosen at runtime via CLI

### What you'll know after Sprint 3
- Trait objects and dynamic dispatch (`Box<dyn Trait>`)
- Object safety rules
- When to use `dyn` vs generics (runtime selection vs compile-time)
- Fat pointers and vtable concept
- Testing strategies for I/O-heavy code

---

## Sprint 4: Async Pipeline — "tokio"

**Goal:** Convert the pipeline to async. Add file tailing (like `tail -f`). Async channels between stages.

**New concepts:** async/await, tokio runtime, `Future` trait, `Pin`, `Stream` trait, `tokio::sync::mpsc`, `Send` bounds on futures, async trait methods

### Key Patterns
```rust
// Async trait (Rust 1.75+ native async traits, or use async-trait crate)
trait AsyncSource {
    async fn read_line(&mut self) -> Option<String>;
}

// Tokio channel between stages
let (tx, mut rx) = tokio::sync::mpsc::channel::<String>(100);

// Spawn tasks for pipeline stages
tokio::spawn(async move {
    while let Some(line) = source.read_line().await {
        tx.send(line).await.unwrap();
    }
});

// Pin is needed when you store a future
use std::pin::Pin;
let fut: Pin<Box<dyn Future<Output = ()> + Send>> = Box::pin(async { ... });
```

### Steps

- [ ] Add `tokio` crate: `cargo add tokio --features full`
- [ ] MUST-KNOW: Async/await in Rust — unlike Python's asyncio, Rust futures are lazy (do nothing until polled). `async fn` returns a `Future`. `.await` polls it. The tokio runtime is the event loop that polls futures. Key difference from Python: Rust futures are zero-cost — no heap allocation unless you Box them.
- [ ] Define `trait AsyncSource` with `async fn read_line(&mut self) -> Option<String>`
- [ ] MUST-KNOW: Async traits — as of Rust 1.75+, traits can have `async fn` methods natively. If you need `dyn AsyncSource`, you'll need the `async-trait` crate or manual desugaring, because async + dyn don't fully work together natively yet.
- [ ] Implement `AsyncFileSource` — wraps `tokio::io::BufReader<tokio::fs::File>`, reads lines async
- [ ] Implement `TailSource` — like `tail -f`: reads a file, then watches for new lines using `tokio::time::sleep` polling loop
- [ ] MUST-KNOW: `Send` bounds — when you `tokio::spawn` a future, it must be `Send` (can move between threads). This means everything captured in the async block must be `Send`. `Rc` is not `Send` (use `Arc`). `&mut` borrows across `.await` points cause issues — the compiler will tell you.
- [ ] Build async pipeline using `tokio::sync::mpsc` channels: source task → channel → transform task → channel → sink task
- [ ] MUST-KNOW: `mpsc` channels — multi-producer, single-consumer. `tx.send(line).await` blocks if channel is full (backpressure!). `rx.recv().await` returns `None` when all senders are dropped (clean shutdown). Channel capacity = buffer size between stages.
- [ ] Wire async pipeline: `TailSource` → `GrepTransform` → `StdoutSink`
- [ ] MUST-KNOW: `Pin` — when a future borrows data across `.await` points, it can't be moved in memory (self-referential). `Pin` prevents moving. You'll encounter this when storing futures in structs or using `Box<dyn Future>`. For now: `Box::pin(future)` when the compiler demands it.
- [ ] Add `#[tokio::main]` to `main.rs`, make main async
- [ ] Test TailSource: write lines to a file in one task, tail in another, verify all lines arrive
- [ ] MUST-KNOW: Testing async — `#[tokio::test]` macro sets up a runtime for each test. Use `tokio::time::timeout` to prevent tests from hanging.
- [ ] Clippy, fmt, all tests pass

### Going Deeper
- [ ] **Add bounded vs unbounded channels** — compare `mpsc::channel(10)` vs `mpsc::unbounded_channel()`. Observe backpressure behavior.
- [ ] **Add a `MetricsTransform`** — counts lines/sec using `tokio::time::Instant`. Practices async state in transforms.
- [ ] **Implement graceful shutdown** — catch Ctrl+C with `tokio::signal::ctrl_c()`, drain pipeline, flush sinks.

### Outcome
✅ **`logpipe --source tail:app.log --transform grep:ERROR --sink stdout`** — tails a live file async, filters, outputs. Pipeline stages connected via async channels.

### What you'll know after Sprint 4
- Async/await fundamentals (lazy futures, polling, tokio runtime)
- Tokio I/O (async file, BufReader)
- `mpsc` channels for inter-task communication
- `Send` bounds and why they matter
- `Pin` concept and when it appears
- Async testing with `#[tokio::test]`

---

## Sprint 5: Workspace + CLI Polish — "Ship It"

**Goal:** Split into multi-crate workspace. Add TOML config for pipeline definitions. Polish CLI.

**New concepts:** cargo workspace, multi-crate structure, `pub use` re-exports across crates, TOML config parsing, builder pattern for pipeline construction

### Key Patterns
```toml
# Root Cargo.toml
[workspace]
members = ["logpipe-core", "logpipe-cli"]

# Pipeline config (pipeline.toml)
[source]
type = "file"
path = "access.log"

[[transform]]
type = "json_parse"
field = "message"

[[transform]]
type = "grep"
pattern = "ERROR"

[sink]
type = "file"
path = "errors.log"
```
```rust
// logpipe-core/src/lib.rs — re-exports
pub mod source;
pub mod transform;
pub mod sink;
pub mod pipeline;
pub mod error;

pub use error::PipeError;
pub use pipeline::Pipeline;
```

### Steps

- [ ] Create workspace structure: root `Cargo.toml` with `[workspace]`, `logpipe-core/`, `logpipe-cli/`
- [ ] MUST-KNOW: Cargo workspaces — one `Cargo.lock` for the whole workspace, shared `target/` dir, but each crate has its own `Cargo.toml`. Dependencies are resolved once across all crates. Build with `cargo build -p logpipe-cli` or `cargo build` (all).
- [ ] Move all trait definitions, sources, transforms, sinks into `logpipe-core`
- [ ] MUST-KNOW: `pub use` re-exports — `logpipe-core/src/lib.rs` should re-export the public API so consumers write `use logpipe_core::Pipeline` not `use logpipe_core::pipeline::Pipeline`. Think of lib.rs as your crate's front door.
- [ ] Create `logpipe-cli` crate, depend on `logpipe-core` via path dependency
- [ ] Move `main.rs` logic into `logpipe-cli/src/main.rs`, update imports
- [ ] Add `toml` crate: `cargo add toml -p logpipe-core`
- [ ] Define a `PipelineConfig` struct (serde-deserializable from TOML)
- [ ] MUST-KNOW: TOML arrays of tables — `[[transform]]` creates a list of transform configs. Each entry is a table. This maps to `Vec<TransformConfig>` in Rust. Serde handles this via `#[serde(tag = "type")]` for enum-based dispatch.
- [ ] Implement `Pipeline::from_config(config: PipelineConfig)` — builds the full pipeline from TOML
- [ ] Add `--config` CLI flag: `logpipe --config pipeline.toml`
- [ ] Keep direct CLI flags working too: `logpipe --source stdin --transform grep:ERROR --sink stdout`
- [ ] Write integration tests at workspace level (`tests/` in workspace root or in `logpipe-cli`)
- [ ] MUST-KNOW: Integration tests in workspaces — tests in `logpipe-cli/tests/` test the binary. Tests in `logpipe-core/tests/` test the library API. Both use only public APIs.
- [ ] Add `README.md` with usage examples for both CLI and TOML config modes
- [ ] Clippy, fmt, all tests (unit + integration) pass across workspace

### Going Deeper
- [ ] **Add `logpipe --validate pipeline.toml`** — parse config and report errors without running. Practice separation of validation from execution.
- [ ] **Add `logpipe --dry-run`** — print the pipeline stages without processing. Shows the resolved config.
- [ ] **Doc comments + `cargo doc`** — document public API of logpipe-core, generate browsable docs

### Outcome
✅ **Multi-crate workspace**: `logpipe --config pipeline.toml` reads a TOML pipeline definition and runs it. Also works with direct CLI flags.

### What you'll know after Sprint 5
- Cargo workspace setup and multi-crate dependencies
- `pub use` re-exports for clean public APIs
- TOML parsing with serde
- Building pipelines from config (factory pattern)
- Integration testing in workspace context

---

## Sprint 6: Extras (Optional)

**Goal:** Polish and extend. Pick any or all.

**New concepts:** `macro_rules!`, `criterion` benchmarks, bounded channels for backpressure, metrics/observability

### Activities

- [ ] **Backpressure** — Use bounded `mpsc::channel(n)` with configurable buffer sizes. Observe what happens when sink is slow: transforms block, source blocks. This IS backpressure — no extra code needed, just bounded channels.
- [ ] **Metrics transform** — Count lines/sec, bytes/sec. Use `tokio::time::interval` to print stats periodically. Practice async timers + shared state.
- [ ] **Pipeline DSL macro** — `pipeline!(stdin | grep("ERROR") | stdout)` using `macro_rules!`. Macros are pattern-matching on token trees. Start simple: fixed number of stages, then make it variadic.
- [ ] MUST-KNOW: `macro_rules!` — Rust's declarative macros. They operate on syntax tokens, not values. Patterns match token trees: `($source:expr | $($transform:expr)|+ | $sink:expr)`. Powerful but hard to debug — use `cargo expand` to see generated code.
- [ ] **Benchmarks with criterion** — Measure throughput: lines/sec for sync vs async pipeline, with/without transforms. `cargo add criterion --dev -p logpipe-core`.
- [ ] **Graceful shutdown** — `tokio::signal::ctrl_c()` + drain channels + flush sinks. Real production behavior.

### Outcome
✅ **Production-quality features**: backpressure, metrics, macro DSL, benchmarks — pick what interests you

### What you'll know after Sprint 6
- Declarative macros (`macro_rules!`)
- Benchmarking with criterion
- Backpressure via bounded channels
- Production patterns (metrics, graceful shutdown)

---

## What You'll Know After This Project

### Trait Design
- ✅ Design traits from scratch (method signatures, mutability, return types)
- ✅ Object safety rules — when `dyn Trait` works and when it doesn't
- ✅ `dyn Trait` vs generics — runtime vs compile-time dispatch tradeoffs

### Async Rust
- ✅ async/await, tokio runtime, lazy futures
- ✅ `tokio::sync::mpsc` channels for concurrent pipeline stages
- ✅ `Send` bounds — why they're required for `tokio::spawn`
- ✅ `Pin` — what it is, when you need it
- ✅ Async testing with `#[tokio::test]`

### Lifetimes & Borrowing (Advanced)
- ✅ When to own vs borrow in struct design
- ✅ Lifetime annotations when borrowing through pipeline stages
- ✅ `BufRead` and buffered I/O patterns

### Iterators & Closures (Advanced)
- ✅ `try_fold` for composable, fallible chains
- ✅ Closure traits in practice (Fn for transforms, FnMut for stateful transforms)
- ✅ Iterator as pipeline abstraction

### Workspace & Architecture
- ✅ Multi-crate cargo workspace
- ✅ `pub use` re-exports for clean crate APIs
- ✅ Config-driven pipeline construction (TOML → pipeline)
- ✅ Integration testing across workspace crates

### Ecosystem
- ✅ tokio (async), regex (patterns), reqwest (HTTP), toml (config)
- ✅ Building on cachebox knowledge: clap, serde, thiserror

### Ready To
After this project, you can:
- ✅ **Design trait hierarchies** for plugin-like architectures
- ✅ **Write async Rust** with tokio — I/O, channels, spawned tasks
- ✅ **Build multi-crate workspaces** with clean public APIs
- ✅ **Make ownership decisions** — own vs borrow, static vs dynamic dispatch
- ✅ **Read async Rust codebases** — understand Pin, Send, Future, Stream

---

## Teaching Instructions (for Claude)

**When resuming a session**:
1. Read "Session State" to identify current sprint and next unchecked item
2. Locate next checkbox in current sprint
3. Teach the concept/step:
   - Start with mental model (1-2 sentences: what it is, why it exists)
   - Show essential Rust code
   - Compare to Python equivalent when it helps (but be clear where Rust differs fundamentally)
   - Connect to cachebox knowledge where relevant ("you used traits as bounds in cachebox, now you're designing traits from scratch")
   - Teach MUST-KNOWs just-in-time (when user encounters the need)
   - Provide real-world example from logpipe project
4. Guide user through implementation:
   - Don't just list steps — walk through them interactively
   - Let user write the code, then review it
   - Answer questions as they arise
   - When user hits a compiler error, use it as a teaching moment
5. Verify user's work:
   - `cargo check` — does it compile?
   - `cargo clippy` — is it idiomatic?
   - `cargo test` — do tests pass?
6. Check the box when user completes the task
7. Update "Session State" with progress

**Teaching style**:
- Short, direct explanations (no essays)
- Mental model first, then code
- MUST-KNOWs when relevant, not upfront
- Real examples from logpipe, not toy examples
- Bridge from cachebox: "in cachebox you used X, here we're doing Y because..."
- Explain what bug the compiler prevents, not just "the compiler won't let you"
- Trait design decisions are collaborative — present tradeoffs, let learner decide

**Verification protocol**:
- After every code change: `cargo check` (compilation)
- After every sprint step: `cargo clippy` (idiomatic check)
- After every sprint: `cargo test` (all tests pass)
- End of each sprint: review full code for quality

**Sprint workflow**:
- Guide user to build one pipeline capability per sprint
- Teach concepts together in context (not in isolation)
- Have user run `cargo check/clippy/test` after each step
- Going Deeper items are optional — offer them but don't block progress
- Let user drive pace

**References**:
- Rust Book: https://doc.rust-lang.org/book/
- std docs: https://doc.rust-lang.org/std/
- Tokio tutorial: https://tokio.rs/tokio/tutorial
- Crate docs: https://docs.rs/{crate}/latest/
- Rust Reference: https://doc.rust-lang.org/reference/
- Async Book: https://rust-lang.github.io/async-book/

---

## Session State

**Current Sprint:** Not started
**Current Step:** —
**Last Updated:** —
**Progress**: 0/5 sprints complete (+ 1 bonus)
