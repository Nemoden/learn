# Slash Command Templates

Five commands form the learning system. Adapt wording to topic but keep structure identical.

## /learn (learn.md)

```markdown
You are my {{TOPIC}} teacher. Read projects/<project>/plan.md (where project is the project directory of $ARGUMENTS project) to see current progress in Session State section. Find the next unchecked checkbox in the current unit. Teach that concept/step using: mental model (1-2 sentences), essential demonstration, MUST-KNOWs just-in-time, real-world example from the project. Guide me through it interactively. When I complete the task, check the box and update Session State. Follow the teaching approach defined in CLAUDE.md.
```

## /til (til.md)

```markdown
Today I Learned $ARGUMENTS.

Append to ./learnings.md in format "- [<date>] <learning description>\n" where <date> is YYYY-MM-DD, <learning description> is concise yet captures necessary information. Add multiple entries if I learned multiple things. Add useful context if it aids future recall.

Important. If I refer to your previous message (e.g., "I learned what you said about {{TOPIC_EXAMPLE}}"), infer exact learning(s) from the conversation. If I point out ONE thing, add exactly that thing, nothing else.

### Response

Respond with "<learning description> added to ./learnings.md"

### Example

When I say: Today I learned about all those concepts (referring to previous message)
→ Add all concepts as separate entries.

When I say: Today I learned about one specific concept
→ Add only that concept.

When I say: Today I learned that X and Y are related because ...
→ Add the learning I called out, not the whole topic.
```

## /know (know.md)

```markdown
Save this reference fact: $ARGUMENTS

Append to ./knowledge.md in format "- [<date>] <fact>\n" where <date> is YYYY-MM-DD.

This file is for **reference facts I'll look up later** — formulas, syntax patterns, command flags, scale shapes, element properties, conversion factors, API signatures, terminology definitions. Different from learnings.md which captures "aha moments."

If my wording is awkward or imprecise, rephrase for clarity and accuracy. If I'm vague (e.g., "save that formula"), infer the specific fact from the previous conversation.

### Response

Respond with "<fact> added to ./knowledge.md"
```

## /review (review.md)

```markdown
Quiz me on my {{TOPIC}} knowledge.

**Sources**: Read ./learnings.md AND ./knowledge.md for quiz material.
**History**: Read ./quiz-log.md (if it exists) to see what I've been quizzed on before.

Select 3-5 entries to quiz. Priority:
1. Entries never quizzed (check quiz-log.md)
2. Entries quizzed but answered wrong last time
3. Oldest entries (most likely forgotten)
4. Conceptually important entries over trivia

For each entry, ask a question that tests **understanding**, not recall. Don't quote the entry — rephrase as a scenario, "what happens if", "why does X work this way", or a problem to solve.

Wait for my answer before revealing the correct answer. After I answer:
- Correct: brief confirmation, move to next
- Partially correct: fill in what I missed
- Wrong: explain correctly, connect back to the learning

After all questions, append results to ./quiz-log.md:
`- [<date>] <entry1_summary> ✅, <entry2_summary> ❌, <entry3_summary> ✅`

Summarize: X/Y correct. If any wrong, suggest reviewing those concepts next session.

$ARGUMENTS can optionally specify: topic filter (e.g., "review ownership"), count (e.g., "review 10"), or "hard" for difficult entries only.
```

## /later (later.md)

```markdown
I'd like to learn $ARGUMENTS later. Add to ./to-learn.md in format "- [<date>] <learning>" where <date> is YYYY-MM-DD.
Rephrase if my wording is awkward.

Respond with <learning> added to ./to-learn.md
```

## Adaptation Notes

- `/learn` — replace `{{TOPIC}}` with topic name
- `/til` — replace `{{TOPIC_EXAMPLE}}` with realistic example (e.g., "Rust lifetimes", "circle of fifths", "Le Chatelier's principle", "git rebase")
- `/review` — replace `{{TOPIC}}` with topic name
- `/know` and `/later` — no topic-specific changes needed
