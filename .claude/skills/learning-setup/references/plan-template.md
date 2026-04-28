# plan.md Template

Every plan.md must follow this skeleton. Adapt content to the topic. Works for code projects, music pieces, science experiments, or any structured learning goal.

**Naming:** Use "Sprint" for Build topics, "Session" for Practice, "Module" for Understand, "Workflow" for Operate — or whatever fits. The template uses "Unit" as a generic placeholder.

---

```markdown
# {{PROJECT_NAME}} — Learning Plan

**Primary Audience**: Claude (AI teaching assistant)
**Purpose**: Teaching script for {{ONE_LINE_DESCRIPTION}}.

**How Claude Uses This File**:
1. **Resume teaching** — Read "Session State" for current unit and next unchecked item
2. **Teach systematically** — Follow checkboxes sequentially, teaching concepts just-in-time
3. **Track progress** — Check boxes as user completes tasks
4. **Guide interactively** — Walk user through activities, don't just list them
5. **Verify work** — {{VERIFICATION_DESCRIPTION}}

**How User Uses This File** (secondary):
- See what's coming next
- Track overall progress
- Reference MUST-KNOWs and key patterns
- Understand the learning structure

**Teaching Approach**: Goal-driven units. Each unit builds one capability, teaching only the concepts needed for that goal. {{GOOD_PRACTICE}} from day 1.

{{IF overview diagram applicable:
## Overview

[Diagram — ASCII art, concept map, system architecture, or skill tree showing how pieces connect]

**Core Goals**: [bullet list of what learner will be able to do]
**Tools/Materials**: [key tools, instruments, materials, frameworks]
}}

---

{{FOR EACH UNIT:}}

## Unit N: {{Title}} — "{{User-Facing Goal}}"

**Goal:** {{One sentence: what the user will be ABLE TO DO after this unit}}

**New concepts:** {{comma-separated list}}

{{IF reference cards applicable:
### Key Patterns
[2-5 essential patterns for this unit's new concepts.
  Code: type signatures, API shapes, config blocks
  Music: chord voicings, scale patterns, rhythm notation
  Science: formulas, reaction templates, unit conversions
  Tools: command syntax, config snippets
Show patterns, NOT full solutions.
]
}}

### Activities

- [ ] {{Activity — action the user takes. Could be: implement, solve, practice, read, experiment, compose, cook}}
- [ ] MUST-KNOW: {{concept}} — {{1-2 sentence explanation of WHY, not just what}}
- [ ] {{More activities, interleaving MUST-KNOWs where the concept is first needed}}
- [ ] {{End unit with verification: tests pass / perform the piece / solve the problem set / execute the workflow}}

{{IF exercises applicable (especially for Understand/Practice topics):
### Exercises
- [ ] {{Problem/drill 1}}
- [ ] {{Problem/drill 2}}
- [ ] {{Problem/drill 3}}
}}

{{IF real-world extras applicable:
### Going Deeper
- [ ] **{{Optional task}}** — {{why it's worth doing}}
- [ ] **{{Optional task}}** — {{brief description}}
}}

### Outcome
✅ **{{What the user can DO or HAS BUILT — tangible result, not abstract knowledge}}**

### What you'll know after Unit N
- {{Concrete skill or concept mastered}}
- {{Another one}}

{{IF chosen stack has alternatives (most Build/Operate topics):
### Here we could also use X
- **{{Alternative 1}}** — {{one line: what swap, when picked over chosen stack}}
- **{{Alternative 2}}** — {{ditto}}
- {{2-5 entries; keep terse; this is anti-tunnel-vision, not a deep dive — that's adjacent.md}}
}}

---

{{END FOR EACH UNIT}}

## What You'll Know After This Project

{{IF 5+ concept areas — structured format:}}

### {{Domain 1}}
- ✅ {{Concrete capability}}

### {{Domain 2}}
- ✅ {{Concrete capability}}

### Ready To
After this project, you can:
- ✅ {{Concrete real-world capability}}

{{ELSE — flat bullet list is fine}}

---

## Teaching Instructions (for Claude)

**When resuming a session**:
1. Read "Session State" to identify current unit and next unchecked item
2. Locate next checkbox
3. Teach the concept/activity:
   - Start with mental model (1-2 sentences: what and why)
   - Show the essential demonstration (code, notation, formula, example, diagram)
   {{IF user has adjacent experience: - Compare to {{ADJACENT}} equivalent when helpful}}
   - Teach MUST-KNOWs just-in-time
   - Provide real-world example from this project
4. Guide user through the activity:
   - Don't just list steps — walk through interactively
   - Let user do the work, then review/critique
   - When user hits an obstacle, use it as a teaching moment
5. Verify:
   {{VERIFICATION — topic-specific:
   Build: cargo check → clippy → test / sam build → deploy → curl
   Practice: "play it and describe what happened" → listen for specific elements → adjust
   Understand: "explain why X works" → pose a variation → check reasoning
   Operate: execute the command → check result → try a variation
   }}
6. Check the box when complete
7. Update "Session State"

**Teaching style**:
- Short, direct explanations
- Mental model first, then demonstration
- MUST-KNOWs when relevant, not upfront
- Real examples from this project, not toy examples
- {{TOPIC_SPECIFIC_STYLE}}

**Verification protocol**:
{{VERIFICATION_CADENCE — when to verify:
  Build: after every code change, after every unit
  Practice: during each activity, at end of session
  Understand: mid-unit quiz checkpoint + end-of-unit exercises
  Operate: after each workflow step
}}

**Unit workflow**:
- Guide user through one goal per unit
- Teach concepts together in context, not isolation
- Going Deeper items are optional — offer but don't block
- Let user drive pace

**References**:
{{DOC_LINKS — official docs, textbooks, local files, URLs}}

---

## Session State

**Current Unit:** Not started
**Current Step:** —
**Last Updated:** —
**Progress**: 0/{{N}} units complete {{(+ M bonus) if applicable}}
```

---

## Template Usage Notes

1. **Outcome lines are REQUIRED** per unit. They describe what the user **can do** or **has built**, not what they learned. Knowledge goes in "What you'll know."

2. **MUST-KNOWs are inline.** They appear at the step where the concept is first needed, not grouped at unit start.

3. **Key Patterns show shapes, not solutions.** For code: type signatures. For music: chord shapes. For science: formula templates. Skip entirely if figuring out the pattern IS the learning.

4. **Exercises are essential for Understand and Practice topics.** Problem sets, drills, practice routines — these aren't optional for knowledge-centric topics.

5. **Teaching Instructions must be self-contained.** The plan should work without reading CLAUDE.md.

6. **Session State needs progress counters.** "0/7 complete" not just "not started."
