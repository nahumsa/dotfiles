---
name: reviewing-dbt-model
description: Reviews a dbt SQL model and its YAML metadata for correctness, maintainability, grain, naming, tests, documentation, and downstream impact. Use when asked to review, audit, critique, or provide feedback on a dbt model without executing dbt commands or querying the warehouse.
user-invocable: true
metadata:
  author: nahumsa
---

# Reviewing a dbt Model

## Core principle

Review the model by inspecting repository files only. Do not execute dbt project tooling or warehouse queries.
If correctness depends on actual data values, grain, null behavior, enum values, or relationship quality, ask the user for clarification or representative samples.

## User invocation

Invoke this skill with the dbt model file path to review:

```text
/skill:reviewing-dbt-model models/path/to/model.sql
```

The argument must be a specific file name, preferably the `.sql` model file. If the user provides only a model name, first locate the matching SQL file. If multiple files match, ask the user to choose one before reviewing.

## Inputs to inspect

When reviewing a model, read:

1. The target model SQL file.
2. The model's YAML file (`.yml` or `.yaml`), usually colocated with the SQL file.
3. Upstream models and sources referenced with `ref()` and `source()`.
4. Downstream models that reference the reviewed model, when the change could affect contracts or semantics.
5. Unit tests, data tests, seeds, fixtures, snapshots, docs, or prior discovery notes related to the model.

## Review workflow

### 1. Identify the model contract

From SQL and YAML, determine:

- Model purpose and business meaning
- Expected grain, primary key, and uniqueness assumptions
- Materialization/configuration if present
- Public columns and documented semantics
- Tests that define expected behavior

If the grain or primary key is not documented, flag it as a review finding.

### 2. Trace dependencies

Inspect each `ref()` and `source()` dependency:

- Confirm the model uses `ref()` and `source()` instead of hardcoded table names.
- Read upstream YAML descriptions before assuming column meaning.
- Check whether transformation logic duplicates logic already present upstream.
- Check whether joins match documented grains and keys.

If join cardinality or orphan behavior cannot be verified from files, ask the user for relationship counts or examples.

### 3. Review SQL quality

Check for:

- Clear CTE structure with meaningful names
- No unnecessary nesting or repeated logic
- Explicit column selection instead of broad `select *` in final outputs
- Consistent naming conventions
- Safe handling of nulls, duplicates, dates, time zones, and type casts
- Filters placed in the appropriate layer of the DAG
- Window functions with deterministic ordering
- Aggregations that match the stated grain
- No hardcoded environment-specific schemas/tables

### 4. Review business logic

Validate logic against documentation and requirements:

- Does the SQL produce the documented grain?
- Are metrics, statuses, and flags clearly defined?
- Are edge cases handled or explicitly documented?
- Are assumptions visible in YAML descriptions or comments?
- Are ambiguous data rules surfaced as questions for the user?

Do not invent data behavior. Ask for clarification when needed.

### 5. Review tests

Check whether tests protect meaningful assumptions:

- Primary key has `unique` and `not_null` tests when appropriate.
- Foreign keys have relationship tests when appropriate.
- Important enums have accepted values only when the valid set is known.
- Critical business rules are tested without excessive low-signal checks.
- Unit tests cover non-obvious transformations and edge cases.

Do not recommend tests that depend on unknown data values without asking the user to confirm those values.

### 6. Review documentation

Check that YAML documentation explains why the model/columns exist, not only what their names say:

- Table description includes purpose, grain, and important caveats.
- Column descriptions explain calculated fields and business semantics.
- Non-obvious assumptions are documented.
- Tests and documentation agree with SQL behavior.

### 7. Assess downstream impact

For potentially breaking changes, search repository SQL/YAML/tests for references to:

- The model name via `ref()`
- Renamed or removed columns
- Changed metrics, flags, or semantic fields

Flag downstream models that may need updates.

## Output format

Return a concise review with these sections:

```markdown
## Summary
Brief overall assessment.

## Findings
### High impact
- [file:line] Finding, why it matters, recommended fix.

### Medium impact
- [file:line] Finding, why it matters, recommended fix.

### Low impact / style
- [file:line] Finding, why it matters, recommended fix.

## Questions / data clarification needed
- Specific question the user must answer before the model can be verified.

## Suggested changes
- Concrete SQL/YAML changes or next steps.
```

If there are no issues in a category, say `None found`.

## Severity guidance

- **High impact:** Incorrect grain, broken joins, likely duplicate rows, metric miscalculation, breaking downstream columns, or undocumented contract changes.
- **Medium impact:** Missing important tests, unclear business rules, non-deterministic logic, maintainability issues that could cause future bugs.
- **Low impact:** Naming, formatting, documentation polish, minor DRY improvements.

## Review rules

- Be specific and cite file paths and line numbers when possible.
- Prefer actionable fixes over generic criticism.
- Do not execute dbt project tooling or warehouse queries.
- Ask for data clarification instead of guessing.
- Do not suggest a new model if extending an existing model would be simpler; surface the tradeoff.
- Respect the existing project's style and layering conventions.
