Look up adjacent-tech / alternatives reference for the current project. Use this any time you want to step back from the chosen stack and see what else could fill the same slot.

Usage:
- `/adjacent` — try to detect the current project from recent context (plan.md being followed, last project worked on). If ambiguous, list available projects and ask.
- `/adjacent <project>` — explicit. Look in `projects/<project>/adjacent.md`.

Behavior:
1. Read `projects/<project>/adjacent.md` end-to-end.
2. Summarize the relevant category if the user gave a hint (e.g., "/adjacent identity-and-orgs SCP" → just the SCP section).
3. For each alternative, surface the one-line description + "when to pick" + "when to skip".
4. If the user picks something they'd like to learn later, append a dated entry to `to-learn.md` at the repo root:
   `- [YYYY-MM-DD] <topic> — <one-line context>`.
5. Do NOT just dump the entire file as a block. Curate to what's relevant to the current sprint or the user's question.

If the project has no `adjacent.md`, say so plainly and offer to scaffold one.
