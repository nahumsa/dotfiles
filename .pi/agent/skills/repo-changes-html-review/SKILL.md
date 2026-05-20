---
name: repo-changes-html-review
description: Generates a static HTML report of repository changes, prioritizing the most important changes first and adding code quality comments. Use when asked to review repo changes, summarize diffs in HTML, produce a change report, or comment on code quality for current git changes.
metadata:
  author: nahumsa
---

# Repo Changes HTML Review

Create a clear, standalone HTML review of changes in the current git repository. The report should put the highest-impact changes first and include practical comments about code quality, risks, and recommended follow-ups.

## Workflow

1. **Confirm scope**
   - If the user did not specify a comparison target, inspect:
     - `git status --short`
     - current branch and upstream via `git branch --show-current` and `git rev-parse --abbrev-ref --symbolic-full-name @{u}` when available
   - Default scope:
     - uncommitted/staged changes if present; otherwise
     - diff against upstream branch; otherwise
     - ask the user for the base branch/commit.

2. **Collect change data**
   - Use git commands such as:
     - `git diff --stat <base>...HEAD`
     - `git diff --name-status <base>...HEAD`
     - `git diff --numstat <base>...HEAD`
     - `git diff <base>...HEAD -- <important-file>`
   - Include untracked files when relevant by reading their contents directly.
   - Do not expose secrets. If a diff appears to contain credentials, tokens, private keys, or sensitive data, call that out and redact values in the HTML.

3. **Prioritize important changes first**
   Rank changed files/areas using this order:
   1. Security, authentication, authorization, secrets, permissions
   2. Public APIs, schemas, migrations, contracts, CLI behavior, breaking changes
   3. Core business logic and data transformations
   4. Error handling, reliability, concurrency, I/O, network behavior
   5. Tests and validation coverage
   6. Build, deployment, dependencies, configuration
   7. Documentation, formatting, comments, low-risk cleanup

4. **Review code quality**
   For important files, inspect the actual diff and nearby code. Comment on:
   - readability and naming
   - cohesion and complexity
   - test coverage and edge cases
   - error handling and observability
   - security and input validation
   - maintainability and consistency with project conventions
   - performance risks, only where meaningful

5. **Generate the HTML report**
   - Write the HTML file directly yourself using the `write` tool. Do **not** generate the report by writing/running a Python script or other helper program unless the user explicitly asks for that implementation approach.
   - Prefer writing a file such as `<name-of-change>.html` in the current working directory unless the user specifies another path.
   - The HTML must be standalone: inline CSS, no external assets, readable in a browser.
   - Add the git diffs view as a separate tab to inspect the changes, pointing to all comments. The diffs should be side-by-side.
   - Recommended sections:
     - Title and metadata: repo, branch, base/scope, timestamp
     - Executive summary: 3-6 bullets
     - Priority review: most important changes first
     - Changed files inventory: table with file, status, additions, deletions, priority, notes
     - Code quality comments: grouped by file/area
     - Risks and follow-ups
     - Validation performed and validation still recommended
   - Use severity/priority labels such as `Critical`, `High`, `Medium`, `Low`, `Info`.

## Output Style

When replying to the user, be concise and include:

- the path to the generated HTML file
- the scope reviewed
- any validations run or skipped
- the top 1-3 risks found
