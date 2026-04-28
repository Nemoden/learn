Show me adjacent technologies / alternatives for $ARGUMENTS project (or the current project if none specified).

**Source**: Read `projects/<project>/adjacent.md` if it exists. This file lists alternative technologies organized by category, with one line per alternative explaining when you'd actually pick it instead of the chosen stack.

**Behavior**:
- If a category filter is given (e.g., "/adjacent ingestion" or "/adjacent storage" or "/adjacent transformation"), show only that category.
- If no filter, show the full structured list grouped by category.
- If user asks a follow-up like "tell me more about X" → expand on that single tech: what it solves better than the chosen stack, when you'd pick it, the "if you only know one thing" insight.
- If `adjacent.md` doesn't exist, scan the current `plan.md` for "Here we could also use X" sections and aggregate them.

This command exists to fight tunnel vision. The point is to know where the stack you're learning sits in the wider landscape — not to learn every alternative deeply, but to recognize them.
