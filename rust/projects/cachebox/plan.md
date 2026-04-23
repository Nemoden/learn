# Cachebox — Learning Plan

**Primary Audience**: Claude (AI teaching assistant)
**Purpose**: Teaching script for building a key-value store with TTL as both a CLI tool and library crate.

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

**Teaching Approach**: Feature-driven sprints. Each sprint builds one working capability, teaching only the Rust concepts needed for that feature. Proper tooling (cargo, clippy, tests) from day 1.

## Architecture Overview

```
┌─────────────────────────────────────────────┐
│                  cachebox                    │
│                                             │
│  src/lib.rs (public API)                    │
│  ├── cache.rs    Cache<V> + methods         │
│  ├── entry.rs    Entry<V> with TTL          │
│  └── error.rs    CacheError (thiserror)     │
│                                             │
│  src/main.rs (CLI — thin wrapper)           │
│  └── clap derive → Cache methods            │
│                                             │
│  Storage: ~/.cache/cachebox/store.json      │
│  Format: serde_json ↔ HashMap<String, Entry>│
└─────────────────────────────────────────────┘

CLI flow:  cachebox set k v --ttl 60
           → load from disk
           → Cache::set(k, v, ttl)
           → save to disk (+ auto-save via Drop)

Lib flow:  let mut c = Cache::new();
           c.set("k", value, Some(Duration::from_secs(60)));
           c.get("k")  // → None after 60s
```

**Core Features**: KV set/get/delete/list, TTL expiration, disk persistence, library + binary crate
**Built with**: clap, serde, thiserror, dirs

---

## Sprint 1: Rust Foundations — "Hello, Cargo"

**Goal:** Understand Rust's ecosystem, toolchain, and workflow. Produce a compilable project with a passing test.

**New concepts:** cargo, project structure, basic types, `String` vs `&str`, `println!` macro, `#[test]`, clippy, rustfmt

### Key Patterns
```rust
fn greet(name: &str) -> String     // accept borrowed, return owned
String::from("hello")              // create owned String
&string_var                        // borrow a String as &str
format!("{} {}", a, b)             // string interpolation
#[test] fn it_works() { assert_eq!(2+2, 4); }
```

### Steps

- [ ] Run `cargo new cachebox` inside `projects/cachebox/`, explore generated structure (`Cargo.toml`, `src/main.rs`)
- [ ] MUST-KNOW: `Cargo.toml` manifest — `[package]`, `[dependencies]`, edition, versioning
- [ ] MUST-KNOW: `String` vs `&str` — owned vs borrowed strings, when to use each
- [ ] Write a `main()` that prints a welcome message, run with `cargo run`
- [ ] MUST-KNOW: `cargo check` (fast) vs `cargo build` (full) vs `cargo run` (build+run)
- [ ] Add a function `fn greet(name: &str) -> String` — first taste of references
- [ ] Write a `#[test]` for `greet()` in the same file, run with `cargo test`
- [ ] Run `cargo clippy` and `cargo fmt` — fix any warnings
- [ ] MUST-KNOW: Rust compiler errors are your teacher — read them fully, they often contain the fix

### Outcome
✅ **Compilable Rust project with a passing test, formatted and linted** — you have a working cargo workflow

### What you'll know after Sprint 1
- cargo workflow (new, check, build, run, test, clippy, fmt)
- Basic Rust syntax, types, functions
- `String` vs `&str` distinction
- How to write and run tests
- How to read compiler errors

---

## Sprint 2: The Store — "Set and Get Values"

**Goal:** Store key-value pairs in memory. First real ownership and borrowing decisions.

**New concepts:** structs, `HashMap`, ownership, borrowing (`&`, `&mut`), `Option<T>`, pattern matching, `impl` blocks

### Key Patterns
```rust
struct Cache { data: HashMap<String, String> }
impl Cache { fn new() -> Self { ... } }
&self      // shared borrow (read)
&mut self  // exclusive borrow (write)
Option<T>  // Some(value) | None
match opt { Some(v) => ..., None => ... }
if let Some(v) = opt { ... }
```

### Steps

- [ ] Define `struct Cache` with a `HashMap<String, String>` field
- [ ] MUST-KNOW: Ownership — each value has exactly one owner. When owner goes out of scope, value is dropped. This prevents use-after-free and double-free bugs.
- [ ] Implement `Cache::new() -> Self`
- [ ] Implement `Cache::set(&mut self, key: String, value: String)`
- [ ] MUST-KNOW: `&mut self` — why does `set` need mutable borrow? What happens if you try `&self`?
- [ ] Implement `Cache::get(&self, key: &str) -> Option<&String>`
- [ ] MUST-KNOW: `Option<T>` — Rust's replacement for null. `Some(value)` or `None`. Pattern match with `match` or use `.unwrap()` (but explain when unwrap is OK vs dangerous)
- [ ] Implement `Cache::delete(&mut self, key: &str) -> bool`
- [ ] Write tests for set/get/delete including edge cases (get missing key, delete missing key)
- [ ] MUST-KNOW: Pattern matching with `match` — exhaustive matching, `if let` shorthand
- [ ] Run clippy — discuss any ownership-related suggestions

### Real-World Extras
- [ ] **Implement `Cache::len(&self)` and `Cache::is_empty(&self)`** — common API patterns
- [ ] **Add `Cache::clear(&mut self)`** — explore `HashMap::clear()` vs dropping and recreating

### Outcome
✅ **In-memory key-value store with set/get/delete and full test coverage**

### What you'll know after Sprint 2
- Structs and impl blocks
- Ownership model (the big one)
- `&self` vs `&mut self` — shared vs exclusive access
- `Option<T>` and pattern matching
- HashMap basics

---

## Sprint 3: CLI Interface — "Make It Usable"

**Goal:** Drive cachebox from the command line with `clap`. First external crate.

**New concepts:** `clap` (derive API), enums with data, `Cargo.toml` dependencies, `match` on enums, `std::process::exit`

### Key Patterns
```rust
#[derive(Parser)]
struct Cli { #[command(subcommand)] command: Command }

#[derive(Subcommand)]
enum Command {
    Set { key: String, value: String },
    Get { key: String },
}

// cargo add clap --features derive
```

### Steps

- [ ] Add `clap` to `Cargo.toml` dependencies (derive feature)
- [ ] MUST-KNOW: Cargo dependency management — `cargo add clap --features derive`, version resolution, `Cargo.lock` purpose
- [ ] Define a `Command` enum using clap's derive API: `Set { key, value }`, `Get { key }`, `Delete { key }`, `List`
- [ ] MUST-KNOW: Rust enums carry data — each variant can hold different types. This is fundamentally different from Python/C enums.
- [ ] Wire `main()` to parse CLI args → match on Command → call Cache methods
- [ ] Implement `Cache::list(&self)` to print all keys
- [ ] Problem: cache is in-memory only, dies when process exits. Acknowledge this — Sprint 5 fixes it.
- [ ] MUST-KNOW: The borrow checker in action — what happens if you try to `get` while `set` has a mutable borrow? Understand the rules: many `&T` OR one `&mut T`, never both.
- [ ] Write integration test: construct Cache, run a sequence of operations, assert results
- [ ] Run clippy, fmt, all tests pass

### Real-World Extras
- [ ] **Add `--json` output flag** — explore conditional formatting, `serde_json::to_string_pretty`
- [ ] **Add `cachebox count` subcommand** — practice adding new enum variants

### Outcome
✅ **`cachebox set/get/delete/list` works from the terminal** — usable CLI tool (data is in-memory only)

### What you'll know after Sprint 3
- Adding and using external crates
- Enums with data (algebraic data types)
- Clap derive API for CLI parsing
- Borrow checker rules in practice
- Cargo.lock and dependency management

---

## Sprint 4: Generics — "Store Any Type"

**Goal:** Make Cache generic over value types. Introduce trait bounds.

**New concepts:** generics (`Cache<V>`), trait bounds (`V: Clone + Display`), `where` clauses, `ToString`/`Display` trait, `derive` macros

### Key Patterns
```rust
struct Cache<V> { data: HashMap<String, V> }
impl<V: Clone + Display> Cache<V> { ... }
// equivalent with where clause:
impl<V> Cache<V> where V: Clone + Display { ... }
#[derive(Debug, Clone, PartialEq)]
```

### Steps

- [ ] Refactor `Cache` from `HashMap<String, String>` to `Cache<V>` with `HashMap<String, V>`
- [ ] MUST-KNOW: Generics — like Python's `list[T]` type hints, but enforced at compile time. Zero runtime cost (monomorphization).
- [ ] Add trait bound `V: Clone` — why Clone? Because `get()` can't return owned data from the HashMap without removing it.
- [ ] MUST-KNOW: `Clone` vs `Copy` — Clone is explicit (`.clone()`), Copy is implicit (stack-only types like `i32`, `bool`). Derive both when appropriate.
- [ ] Add `V: std::fmt::Display` bound so values can be printed
- [ ] MUST-KNOW: `where` clause syntax — when bounds get long, move them to `where` block for readability
- [ ] Update CLI to use `Cache<String>` (still string values from CLI, but the library is now generic)
- [ ] MUST-KNOW: `derive` macros — `#[derive(Debug, Clone)]` auto-generates trait implementations. Understand what Debug, Clone, PartialEq do.
- [ ] Add `Debug` derive to Cache struct, test with `{:?}` formatting
- [ ] Update all tests, clippy, fmt

### Real-World Extras
- [ ] **Implement `Display` trait manually for Cache** — understand `impl fmt::Display for Cache<V>` and `write!` macro
- [ ] **Explore `Cow<'a, str>`** — borrow when you can, clone when you must. Common in APIs that accept both `&str` and `String`.

### Outcome
✅ **Cache accepts any type (`Cache<V>`)** — library is generic, CLI still uses `Cache<String>`

### What you'll know after Sprint 4
- Generic type parameters and monomorphization
- Trait bounds (constraining what V can be)
- Clone vs Copy semantics
- Derive macros for common traits
- Where clauses for readable bounds

---

## Sprint 5: Error Handling & Persistence — "Survive Restarts"

**Goal:** Serialize cache to disk with serde. Proper error handling with `Result<T, E>`.

**New concepts:** `Result<T, E>`, `?` operator, `thiserror`, `serde` + `serde_json`, file I/O (`std::fs`), `From` trait for error conversion

### Key Patterns
```rust
#[derive(Debug, thiserror::Error)]
enum CacheError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),
}

fn save(&self) -> Result<(), CacheError> {
    let json = serde_json::to_string(&self.data)?;  // ? converts error
    std::fs::write(&self.path, json)?;
    Ok(())
}
```

### Steps

- [ ] Add `serde`, `serde_json` to dependencies. Add `Serialize`/`Deserialize` derives to Cache.
- [ ] MUST-KNOW: `serde` — Rust's universal serialization framework. `#[derive(Serialize, Deserialize)]` works for most types automatically. Equivalent of Python's `json.dumps`/`json.loads` but type-safe.
- [ ] Add trait bound `V: Serialize + DeserializeOwned` to Cache
- [ ] MUST-KNOW: `Serialize` vs `DeserializeOwned` vs `Deserialize<'de>` — owned deserialization is simpler (no lifetime gymnastics). Use `DeserializeOwned` unless you need zero-copy.
- [ ] Implement `Cache::save(&self, path: &Path) -> Result<(), CacheError>`
- [ ] MUST-KNOW: `Result<T, E>` — Rust's error handling. No exceptions. Every fallible operation returns `Result`. `Ok(value)` or `Err(error)`.
- [ ] Define `CacheError` enum with `thiserror` — variants for `Io(#[from] std::io::Error)`, `Serialization(#[from] serde_json::Error)`
- [ ] MUST-KNOW: `?` operator — early return on error. `file.read_to_string(&mut s)?` returns the error to caller if it fails. Replaces verbose `match` on every Result.
- [ ] MUST-KNOW: `#[from]` in thiserror — auto-generates `From` trait impls so `?` can convert `io::Error` → `CacheError::Io` automatically
- [ ] Implement `Cache::load(path: &Path) -> Result<Self, CacheError>`
- [ ] Wire persistence into CLI: load on start, save after mutations
- [ ] MUST-KNOW: `dirs` crate — use XDG-compliant paths (`~/.cache/cachebox/`) instead of hardcoded paths
- [ ] Add `dirs` crate, store cache file at proper location
- [ ] Write tests: save → load → verify data intact. Test error cases (bad JSON file, missing dir).
- [ ] Clippy, fmt, all tests pass

### Real-World Extras
- [ ] **Add `bincode` as alternative backend** — binary format, much faster than JSON. Compare file sizes and speed.
- [ ] **Implement `anyhow` in main.rs** — `anyhow::Result` for application code vs `thiserror` for library code. Understand the distinction.
- [ ] **Add `Cache::export(&self, format: Format)`** — explore enum-based format dispatch (JSON vs TOML vs bincode)

### Outcome
✅ **Data survives restarts** — `cachebox set k v` persists to `~/.cache/cachebox/store.json`, loads on next run

### What you'll know after Sprint 5
- Result<T, E> and the ? operator
- Custom error types with thiserror
- Serde serialization/deserialization
- File I/O with std::fs
- From trait for error conversion
- XDG directory conventions

---

## Sprint 6: TTL Expiration — "Values That Die"

**Goal:** Add time-to-live. Introduce `Drop` trait, `std::time`, more complex generics.

**New concepts:** `std::time::{Instant, Duration}`, `Drop` trait, `Option<Duration>`, interior struct design, iterators for cleanup

### Key Patterns
```rust
struct Entry<V> {
    value: V,
    created_at: SystemTime,
    ttl: Option<Duration>,
}
impl<V> Entry<V> {
    fn is_expired(&self) -> bool { ... }
}
// Iterator: retain only non-expired
self.data.retain(|_, entry| !entry.is_expired());
// Closures: |k, v| captures by reference (Fn)
// Drop: impl Drop for Cache<V> { fn drop(&mut self) { self.save(); } }
```

### Steps

- [ ] Define `struct Entry<V>` with `value: V`, `created_at: SystemTime`, `ttl: Option<Duration>`
- [ ] Refactor Cache to use `HashMap<String, Entry<V>>`
- [ ] Update `set()` to accept optional TTL: `set(&mut self, key: String, value: V, ttl: Option<Duration>)`
- [ ] Update `get()` to check expiration: if expired, return `None` and remove entry
- [ ] MUST-KNOW: `Instant` vs `SystemTime` — Instant is monotonic (can't go backwards), use for measuring durations. SystemTime is wall clock (can jump), use for timestamps humans see. Use SystemTime here because it survives serialization.
- [ ] Implement `Cache::cleanup(&mut self)` — iterate and remove all expired entries
- [ ] MUST-KNOW: Iterator patterns — `.retain()` for in-place filtering, `.iter().filter()` for lazy filtering, `.collect()` for materializing. Iterators are zero-cost abstractions in Rust.
- [ ] MUST-KNOW: Closures — `|k, v| v.is_expired()`. Three closure traits: `Fn` (borrow), `FnMut` (mutable borrow), `FnOnce` (consume). Compiler infers which one.
- [ ] Update CLI: `cachebox set key value --ttl 60`
- [ ] Update serialization — add `Serialize`/`Deserialize` derives to `Entry<V>`, handle `SystemTime` serialization
- [ ] MUST-KNOW: `Drop` trait — custom cleanup logic when a value goes out of scope. Implement `Drop` for Cache to auto-save on exit.
- [ ] Implement `Drop` for Cache: save to disk when Cache is dropped
- [ ] Write tests: set with TTL → get before expiry (Some) → wait/mock → get after expiry (None)
- [ ] Clippy, fmt, all tests pass

### Real-World Extras
- [ ] **Add `Cache::stats(&self)`** — count total, expired, active entries. Practice iterator chains: `.filter().count()`
- [ ] **Implement background cleanup** — `std::thread::spawn` a cleanup loop. First taste of threading before the bonus sprint.
- [ ] **Benchmark with `cargo bench`** — set up a basic benchmark measuring set/get/cleanup throughput. Explore `criterion` crate.

### Outcome
✅ **`cachebox set k v --ttl 60` works** — values auto-expire, cache auto-saves on exit via Drop

### What you'll know after Sprint 6
- Time handling (Instant, Duration, SystemTime)
- Drop trait (RAII pattern)
- Iterator adaptors and closures
- Closure trait hierarchy (Fn/FnMut/FnOnce)
- Complex struct composition

---

## Sprint 7: Library Crate — "Ship It as a Crate"

**Goal:** Split into lib + bin. Proper module structure, public API design, documentation.

**New concepts:** `lib.rs` vs `main.rs`, `pub`/`pub(crate)`, `mod` tree, doc comments (`///`), `cargo doc`, integration tests (`tests/` dir), `cargo publish` workflow

### Key Patterns
```rust
// src/lib.rs — public API surface
pub mod cache;
pub mod error;
mod entry;  // private — implementation detail
pub use cache::Cache;
pub use error::CacheError;

// Doc comment with runnable example
/// Create a new cache and store a value.
/// ```
/// let mut c = cachebox::Cache::new();
/// c.set("key".into(), "value".into(), None);
/// assert_eq!(c.get("key"), Some(&"value".into()));
/// ```

// Accept broad types, return specific types
fn set(&mut self, key: impl Into<String>, value: V, ttl: Option<Duration>)
```

### Steps

- [ ] Restructure: `src/lib.rs` (Cache, Entry, CacheError) + `src/main.rs` (CLI only)
- [ ] MUST-KNOW: lib.rs vs main.rs — a crate can be both a library (importable by others) and a binary (runnable). `lib.rs` = public API, `main.rs` = thin CLI wrapper that uses the library.
- [ ] Extract modules: `src/cache.rs`, `src/entry.rs`, `src/error.rs` — re-export from `lib.rs`
- [ ] MUST-KNOW: Module system — `mod cache;` in lib.rs looks for `src/cache.rs`. Visibility: `pub` (world), `pub(crate)` (crate only), `pub(super)` (parent module), private (default).
- [ ] Design public API: what's `pub` and what's hidden? Entry internals should be private, Cache methods public.
- [ ] MUST-KNOW: API design in Rust — accept `&str` not `String` in function args (more flexible), return `String` when caller needs ownership. Accept generics (`impl Into<String>`) for ergonomic APIs.
- [ ] Add doc comments (`///`) to all public items. Include examples in doc comments.
- [ ] MUST-KNOW: `cargo doc --open` generates browsable HTML docs. Doc comment examples are run as tests (`cargo test` runs them). Doc tests = documentation that can't go stale.
- [ ] Move integration tests to `tests/` directory (separate from unit tests in `src/`)
- [ ] MUST-KNOW: `tests/` dir = integration tests. They can only use your public API (like an external consumer). Unit tests in `src/` can access private items via `#[cfg(test)] mod tests`.
- [ ] Add `README.md` with usage examples
- [ ] Run `cargo package --list` to see what would be published. Discuss `cargo publish` workflow (crates.io).
- [ ] Final: clippy, fmt, all tests (unit + integration + doc tests) pass

### Real-World Extras
- [ ] **Add `#[must_use]` attribute** to functions returning `Result` — understand why Rust warns on unused Results
- [ ] **Add `cargo-readme`** — auto-generate README from doc comments. Explore the Rust documentation ecosystem.
- [ ] **Explore `#[cfg(feature = "...")]`** — add an optional `json` feature flag that enables serde_json backend. Understand conditional compilation.

### Outcome
✅ **cachebox is a publishable crate** — `cargo package` succeeds, docs generate, all test types pass (unit + integration + doc tests)

### What you'll know after Sprint 7
- Crate structure (lib + bin)
- Module system and visibility
- Public API design principles
- Doc comments and doc tests
- Integration test patterns
- Publishing workflow

---

## Bonus Sprint: Concurrency (Optional)

**Goal:** Thread-safe cache for use from multiple threads.

**New concepts:** `Arc<Mutex<T>>`, `Send` + `Sync` traits, thread safety guarantees, `RwLock` vs `Mutex`

### Key Patterns
```rust
use std::sync::{Arc, RwLock};
let cache = Arc::new(RwLock::new(Cache::new()));
// Read: let guard = cache.read().unwrap();
// Write: let mut guard = cache.write().unwrap();
// Clone Arc for each thread: let c = Arc::clone(&cache);
```

### Steps

- [ ] Wrap Cache in `Arc<Mutex<Cache<V>>>` — understand why both are needed
- [ ] MUST-KNOW: `Arc` = atomic reference counting (shared ownership across threads). `Mutex` = mutual exclusion (only one thread accesses at a time). Combined: multiple threads can share and mutate data safely.
- [ ] MUST-KNOW: `Send` + `Sync` — compiler auto-derives these. `Send` = safe to transfer between threads. `Sync` = safe to share references between threads. If your type contains non-Send/Sync fields, compiler will catch it.
- [ ] Write a test: spawn 10 threads, each setting 100 keys concurrently. Verify no data loss.
- [ ] MUST-KNOW: `RwLock` vs `Mutex` — RwLock allows many readers OR one writer. Mutex allows one accessor period. Use RwLock when reads >> writes.
- [ ] Refactor to `Arc<RwLock<Cache<V>>>` — get() takes read lock, set()/delete() take write lock
- [ ] Clippy, fmt, all tests pass

### Real-World Extras
- [ ] **Add `dashmap` crate** — concurrent HashMap that doesn't need external Mutex. Compare API ergonomics.
- [ ] **Benchmark Mutex vs RwLock vs DashMap** — measure under read-heavy and write-heavy workloads

### Outcome
✅ **Cache is thread-safe** — 10 threads writing concurrently with zero data loss

### What you'll know after Bonus Sprint
- Thread-safe data sharing (Arc + Mutex/RwLock)
- Send + Sync traits
- Practical fearless concurrency

---

## What You'll Know After This Project

### Ownership & Memory Model
- ✅ Ownership rules and why they exist (preventing use-after-free, double-free, data races)
- ✅ Borrowing: `&T` vs `&mut T`, borrow checker rules
- ✅ Clone vs Copy semantics
- ✅ Drop trait and RAII pattern
- ✅ Smart pointers (Arc, Mutex, RwLock)

### Type System & Traits
- ✅ Structs with impl blocks
- ✅ Enums with data (algebraic data types)
- ✅ Generics with trait bounds and where clauses
- ✅ Core traits: Clone, Copy, Debug, Display, Drop, From, Serialize/Deserialize
- ✅ Derive macros for automatic trait implementation

### Error Handling
- ✅ `Result<T, E>` as the standard error pattern
- ✅ `?` operator for ergonomic error propagation
- ✅ Custom error types with `thiserror` (libraries) vs `anyhow` (applications)
- ✅ `From` trait for error conversion

### Iterators & Closures
- ✅ Iterator trait, adaptors (filter, map, collect, retain)
- ✅ Closure types (Fn, FnMut, FnOnce) and when each applies
- ✅ Zero-cost abstractions — iterators compile to loops

### Crate Ecosystem
- ✅ clap (CLI), serde (serialization), thiserror (errors), dirs (paths)
- ✅ Cargo: add, build, test, clippy, fmt, doc, package
- ✅ Cargo.toml, Cargo.lock, features, dependency management

### Module System & API Design
- ✅ lib.rs vs main.rs — library + binary crate
- ✅ Module tree, visibility (pub, pub(crate))
- ✅ Public API design: accept broad, return specific
- ✅ Doc comments, doc tests, integration tests

### Concurrency (Bonus)
- ✅ Arc + Mutex/RwLock for shared mutable state
- ✅ Send + Sync traits — compiler-enforced thread safety
- ✅ Choosing Mutex vs RwLock based on access patterns

### Career-Ready
After this project, you can:
- ✅ **Read and write idiomatic Rust** — ownership, traits, error handling are second nature
- ✅ **Build CLI tools** with proper argument parsing, error reporting, and persistence
- ✅ **Design library APIs** with docs, tests, and proper visibility
- ✅ **Join Rust projects** with practical experience, not just book knowledge
- ✅ **Evaluate crates** — know the de-facto standards (serde, clap, thiserror) and when to use them

---

## Teaching Instructions (for Claude)

**When resuming a session**:
1. Read "Session State" to identify current sprint and next unchecked item
2. Locate next checkbox in current sprint
3. Teach the concept/step:
   - Start with mental model (1-2 sentences: what it is, why it exists)
   - Show essential Rust code
   - Compare to Python equivalent when it helps (but be clear where Rust differs fundamentally)
   - Teach MUST-KNOWs just-in-time (when user encounters the need)
   - Provide real-world example from cachebox project
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
- Real examples from cachebox, not toy examples
- Explain what bug the compiler prevents, not just "the compiler won't let you"
- No `unwrap()` without explaining when it's acceptable

**Verification protocol**:
- After every code change: `cargo check` (compilation)
- After every sprint step: `cargo clippy` (idiomatic check)
- After every sprint: `cargo test` (all tests pass)
- End of each sprint: review full code for quality

**Sprint workflow**:
- Guide user to build one feature per sprint
- Teach concepts together in context (not in isolation)
- Have user run `cargo check/clippy/test` after each step
- Real-World Extras are optional — offer them but don't block progress

**File references**:
- Rust Book: https://doc.rust-lang.org/book/
- std docs: https://doc.rust-lang.org/std/
- Crate docs: https://docs.rs/{crate}/latest/
- Rust Reference: https://doc.rust-lang.org/reference/

---

## Session State

**Current Sprint:** Not started
**Current Step:** —
**Last Updated:** —
**Progress**: 0/7 sprints complete (+ 1 bonus)
