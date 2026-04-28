---
name: learning-setup
description: "Bootstrap a learning environment for any topic — programming, music, science, languages, anything. Generates: CLAUDE.md (tutor personality), slash commands (/learn, /til, /later, /review, /know), settings, tracking files, and optional project structure. Triggers: 'setup learning for', 'learn <topic>', 'create learning env', 'bootstrap <topic> learning', 'set up <topic>/ to learn', 'teach me <topic>'."
---

# Learning Environment Setup

Scaffold a self-contained learning directory for any topic. The same pedagogy patterns work whether the topic is Rust, chemistry, piano, or AWS.

## Topic Categories

Classify by **how the topic is learned**, not what it is. This determines plan structure, verification method, and learning unit naming.

| Category | Examples | Verification | Learning unit | Plan style |
|---|---|---|---|---|
| **Build** | Rust, AWS, React, woodworking, electronics | Run/compile/deploy/test the artifact | Sprint (feature-driven) | Progressive project — each sprint adds a capability |
| **Practice** | Piano, drawing, cooking, spoken language, typing | Perform + critique the output | Session (drill-driven) | Repertoire — each session works toward a performable piece/dish/conversation |
| **Understand** | Chemistry, music theory, physics, history, math | Q&A, problem sets, explain-back | Module (concept-driven) | Concept map — each module builds on prerequisites, exercises test understanding |
| **Operate** | Git, Docker, Nix, Excel, Photoshop | Execute workflow in real tool | Workflow (task-driven) | Checklist — each workflow masters a real task, shorter plans (3-5 units) |

Many topics are hybrids. Music = Practice + Understand. AWS = Build + Operate. Pick the primary mode for plan structure, weave in the secondary.

## Workflow

### Step 0: Check for Existing Setup

Check if `<topic>/` already exists under the learn repo root. If it does:
- Read existing CLAUDE.md to understand current setup
- Ask user: update existing setup, or start fresh?
- If updating: only modify/add what's missing, never overwrite user content (learnings.md, to-learn.md, quiz-log.md)

### Step 1: Gather Requirements

Ask user (keep brief, 2-3 questions max):
1. What topic?
2. What's your current level? (complete beginner / some exposure / experienced in adjacent area)
3. Any specific goal or project? — if none, suggest 3-5 based on topic + level

Classify into category (Build/Practice/Understand/Operate). State the classification so user can correct it.

### Step 2: Generate Directory Structure

Create under the learn repo root:

```
<topic>/
├── .claude/
│   ├── settings.json
│   └── commands/
│       ├── learn.md      (resume from plan.md checkpoint)
│       ├── til.md        (capture aha moments)
│       ├── later.md      (park tangents)
│       ├── review.md     (spaced-repetition quiz)
│       ├── know.md       (save reference facts)
│       └── adjacent.md   (browse adjacent-tech / alternatives reference)
├── CLAUDE.md
├── README.md
├── learnings.md           (empty — aha moments accumulate here)
├── knowledge.md           (empty — reference facts accumulate here)
├── quiz-log.md            (empty — review results tracked here)
├── to-learn.md            (seed with 3-5 future topics)
├── TODO.md                (empty or seed with first project idea)
└── projects/              (learning projects go here)
```

Optional (ask if relevant):
- `flake.nix` + `.envrc` — only if topic has installable tools/runtimes. Read [references/flake-template.md](references/flake-template.md) for the pattern.
- `<topic>-docs/` — if topic has downloadable reference material (official docs, textbooks, PDFs)

### Step 3: Generate Files

**CLAUDE.md** — Read [references/claude-md-template.md](references/claude-md-template.md). Core file. Adapt every section to the topic:
- Teaching method (code? notation? diagrams? formulas? recipes?)
- Doc sources (URLs, local files, textbooks)
- Verification method (compile? perform? explain-back? solve problems?)
- Topic-specific "do not" rules
- Concept categories organized by functional domain

**Slash commands** — Read [references/commands.md](references/commands.md). Six commands: `/learn`, `/til`, `/later`, `/review`, `/know`, `/adjacent`. Stable across topics with minor wording tweaks.

**settings.json**:
- `"outputStyle": "Learning"` (always)
- `"includeCoAuthoredBy": false` (always)
- Topic-specific env vars if needed
- Topic-specific permission allows if needed

**README.md** — Brief: "My <topic> learning journey with Claude Code." + link to first project.

**flake.nix** — Only if topic has installable tools. Use [references/flake-template.md](references/flake-template.md).

### Step 4: Seed Initial Content

- `to-learn.md` — 3-5 interesting future topics (dated)
- `TODO.md` — First project idea if user has one

### Step 5: Generate plan.md (if project exists)

Read [references/plan-template.md](references/plan-template.md) for **required structure**.
Read [references/plan-techniques.md](references/plan-techniques.md) for **optional techniques**.

**Interactive plan generation:**
1. Propose 3-5 project/goal ideas if user doesn't have one
2. Propose unit structure (names + concepts per unit) as brief outline
3. Ask user to confirm or adjust before generating
4. Generate full plan.md following template, applying relevant techniques

**Required in every plan:**
- Header (audience, purpose, how-to-use)
- Units with: Goal, New concepts, Steps/Activities (w/ inline MUST-KNOWs), Outcome, What you'll know
- Teaching Instructions section (self-contained)
- Session State with progress counters

**Anti-tunnel-vision (recommended for any topic with a chosen stack):**
- Each unit ends with a "Here we could also use X" subsection — adjacent technologies / alternatives that swap for what the unit just taught, with one line on when each would actually be picked
- Project gets a standalone `adjacent.md` reference file under `projects/<project>/` listing alternatives by category (storage, compute, transformation, BI, etc.)
- Project's last unit can be an "Adjacent Tech Acknowledgement" survey unit — guided read+discuss instead of build, ending with 1-2 picks added to `to-learn.md`
- `/adjacent` slash command surfaces this list at any time during the project
- Cross-pollination cadence baked into Teaching Instructions: present per-unit "Here we could also use X" briefly after main activities; the standalone `adjacent.md` is the always-available deeper reference

This pattern matters because narrow learning produces locked-in engineers. Naming the alternatives (and their use cases) at the moment a concept is taught builds the mental map of where the chosen stack sits.

**Technique defaults by category:**

| Technique | Build | Practice | Understand | Operate |
|---|---|---|---|---|
| Architecture/overview diagram | When 3+ components | Rarely | Concept map when 5+ topics | Rarely |
| Reference cards | Patterns/signatures | Notation/fingerings/recipes | Formulas/rules/mnemonics | Command cheatsheets |
| Real-World Extras | Production hardening | Performance variations | Edge cases, harder problems | Advanced flags/config |
| Inline examples | Config/boilerplate only | Notation/sheet music | Worked problems | Commands/config |
| Unit 0: setup | If tools need install | If instruments/materials needed | Rarely | Usually |
| Structured finale | 5+ units | Always (repertoire list) | 5+ units | Rarely |
| Exercise blocks | Via tests | Core to every session | Core to every module | Via real tasks |
| Quiz checkpoints | End of unit | End of session | Mid-unit AND end | End of workflow |
| "Here we could also use X" per unit | Always (technology stacks crowded) | When alternative methods/styles exist | When alternative theories/frameworks exist | Always (tools always have alternatives) |
| Standalone adjacent.md reference | Always for projects | Optional | Optional | Always for projects |
| Final adjacent-survey unit | When 5+ units AND crowded ecosystem | Optional | Optional | Optional |

### Step 6: Verify & Report

List what was created. Remind user:
1. `cd <topic>/` and start Claude there
2. `/learn <project>` — begin guided learning
3. `/til <thing>` — capture aha moments
4. `/know <fact>` — save reference material
5. `/later <topic>` — park tangents
6. `/review` — quiz on accumulated learnings
7. `/adjacent <project>` — browse adjacent-tech / alternatives at any time

## Guidelines

- **Truly universal.** Chemistry, piano, Rust, cooking — same skill, same quality.
- **No generic filler.** Every line in CLAUDE.md must earn its place for this specific topic.
- **Verification exists for everything.** Code compiles. Music sounds right. Chemistry equations balance. History arguments hold up. Find the verification method and bake it in.
- **Plans are interactive.** Confirm unit structure with user before generating.
- **Plans follow the template.** Required skeleton from plan-template.md. Techniques are optional.
- **Classify the topic.** Build/Practice/Understand/Operate determines defaults.
- **The skill is the flywheel.** Improvements discovered during generation should be noted for the user to feed back into the skill.
