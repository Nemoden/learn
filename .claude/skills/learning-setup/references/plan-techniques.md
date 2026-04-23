# Plan Techniques Catalog

Evaluate each technique when generating a plan.md. Not all apply to every topic or project.

## Required (every plan)

### 1. Teaching Instructions Section
Self-contained at bottom of plan.md. Claude can teach from this plan alone.

### 2. Session State
Bottom of file. Tracks: current unit, next step, last updated, progress fraction.

### 3. Per-Unit Outcome + "What You'll Know"
Every unit ends with both:
- **Outcome** — tangible artifact/capability (what you CAN DO)
- **What you'll know** — concepts mastered (what you UNDERSTAND)

### 4. MUST-KNOW Markers
Inline with activities, at the step where the concept is first needed.

### 5. Verification Protocol
Embedded in Teaching Instructions. Topic-specific:
- **Build**: run/compile/test commands (e.g., `cargo check`, `sam deploy`)
- **Practice**: perform + describe + compare to reference
- **Understand**: explain-back, solve a variation, derive from principles
- **Operate**: execute workflow, check result, try edge case

## Recommended (when applicable)

### 6. Overview Diagram
**Include when:** 3+ interacting components, complex concept relationships, or multi-stage system.
**Skip when:** Linear progression, single-module project, obvious from unit list.

Types: ASCII architecture diagram (Build), concept map (Understand), skill tree (Practice), workflow flowchart (Operate).

### 7. Going Deeper (optional extras per unit)
**Include when:** Topic has natural stretch tasks — production hardening, advanced variations, edge cases, harder problems, performance tips.
**Skip when:** Unit is already dense.

Never blocks progression. Labeled clearly as optional.

### 8. Reference Cards (Key Patterns per unit)
**Include when:** Topic has stable patterns users look up repeatedly.
  - Build: API signatures, config blocks, type patterns
  - Practice: notation, fingering charts, recipe ratios, technique cues
  - Understand: formulas, rules, mnemonics, conversion tables
  - Operate: command syntax, flag reference, config snippets

**Skip when:** The pattern IS the thing to learn (e.g., algorithm design).

Show shapes, not solutions.

### 9. Exercise Blocks
**Include when:** Understand or Practice topics — these NEED exercises, they're not optional.
  - Understand: problem sets, derivations, "explain why", "predict what happens if"
  - Practice: drills, etudes, timed exercises, variations on theme

**Skip when:** Build/Operate topics where the implementation IS the exercise.

### 10. Quiz Checkpoints
**Include when:** Understand topics — add mid-unit "check your understanding" checkboxes.
**Format:** `- [ ] CHECKPOINT: Can you explain {{concept}} without looking at notes?`

Lighter than exercises — just a pause to verify comprehension before moving on.

### 11. Structured Finale
**Include when:** 5+ units, multiple concept domains, career/practical relevance.
**Skip when:** Short plans (3-4 units), single domain.

Organize by domain, not chronologically. Include "Ready To" section with concrete capabilities.

### 12. Unit 0: Setup
**Include when:** Non-trivial tool/material/credential setup that could block learning.
  - Build: tool installation, credentials, project scaffolding (if nix flake doesn't handle it)
  - Practice: instrument setup, software installation, workspace preparation
  - Understand: textbook/material acquisition, prerequisite verification
  - Operate: tool installation, account setup, credential configuration

**Skip when:** Setup is handled by nix flake, or is trivial (one command).

### 13. Inline Examples in Activities
**Include when:** Topic has boilerplate/config/notation that must be exact — getting syntax wrong wastes time on typos, not learning.
  - Build: YAML templates, config files, boilerplate (NOT business logic)
  - Practice: sheet music notation, recipe steps with exact measurements
  - Understand: worked example of a formula application
  - Operate: exact command with flags

**Skip when:** The content IS the learning. Don't give away what the learner should figure out.

## Anti-Patterns

- **Don't put full solutions in the plan.** Show patterns, not answers.
- **Don't front-load MUST-KNOWs.** Just-in-time, always.
- **Don't make Going Deeper block progress.**
- **Don't skip exercises for Understand/Practice topics.** They're not optional — they're the core learning mechanism.
- **Don't assume code.** "Tests pass" is one verification method. "Can you explain why" is another. "Play it at tempo" is another. Match the topic.
- **Don't over-structure short plans.** 3 units don't need architecture diagrams or career sections.
