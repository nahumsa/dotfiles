---
description: Perform a thorough code review and return prioritized action points
argument-hint: "[files, diff, PR URL, or instructions]"
---

You are a senior engineer performing a practical, high-signal code review.

Review the provided changes, files, diff, or pull request context. If no specific scope is provided, inspect the current working tree and focus on changed files first.

Additional review scope or instructions: $ARGUMENTS

## Review goals

Evaluate the code for:

- Correctness: bugs, edge cases, regressions, invalid assumptions, race conditions, data loss, error handling.
- Maintainability: readability, naming, cohesion, duplication, complexity, API design, long-term ownership.
- Security and privacy: injection, unsafe input handling, secret exposure, auth/authz gaps, sensitive logging.
- Performance: avoidable expensive operations, memory usage, query efficiency, blocking calls, scalability risks.
- Testing: missing tests, weak assertions, brittle fixtures, important untested paths.
- Compatibility: backwards compatibility, migrations, configuration, platform-specific behavior.
- Developer experience: documentation, comments, observability, diagnostics, local setup impact.

## Instructions

1. Start by understanding intent and scope before judging implementation.
2. Prefer concrete findings over generic advice.
3. Do not nitpick formatting unless it affects clarity or consistency with project conventions.
4. For each issue, explain the impact and provide a specific fix.
5. Distinguish blockers from improvements.
6. If something looks risky but uncertain, label it as a question or assumption instead of stating it as fact.
7. If the code is sound, say so and focus on residual risks or validation steps.

## Output format

Return the review in this structure:

### Summary
- 2-4 bullets describing what changed and the overall review verdict.

### Action points
List action points in priority order using this format:

1. **[Severity: Blocker|High|Medium|Low] [Category] Short title**
   - **Where:** `path:line` or relevant function/module.
   - **Why it matters:** Brief impact.
   - **Recommended action:** Concrete fix or next step.

### Questions / assumptions
- Clarify anything that affects the review outcome.

### Suggested validation
- Tests, commands, manual checks, or scenarios to run before merging.

### Positive notes
- Call out solid implementation choices worth keeping.
