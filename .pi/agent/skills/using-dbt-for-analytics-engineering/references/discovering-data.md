# Discovering Data by Inspecting Models and Clarifying Assumptions

Use repository inspection and user clarification to understand raw data, table structures, and downstream model requirements. Do not execute project tooling or warehouse queries as part of discovery unless the user explicitly asks you to.

## When to Use

- Onboarding to a new dbt project with unfamiliar source data
- Investigating data quality issues reported by stakeholders
- Planning new models and needing to understand source grain/structure
- Mapping relationships between tables before building joins

## The Iron Rule

**Complete all 6 steps for every table you will build models on.** If any step requires actual data that is not available in the repository, ask the user for clarification, a representative sample, or a profiling summary.

## Rationalizations That Mean STOP

| You're Thinking... | Reality |
|-------------------|---------|
| "I don't have time for full discovery" | You don't have time for wrong models. |
| "It's just a quick stakeholder briefing" | Quick briefings become "can you build a model from this?" You need discovery before building anything. |
| "I'll do proper discovery later" | You won't. Document now or create technical debt someone else inherits. |
| "This is technical debt I'm accepting" | You're not accepting it - you're passing it to your future self or teammates. |
| "47 tables is too many for full methodology" | Then prioritize which tables you'll actually use and do full discovery on those. Don't half-discover everything. |
| "I'll just do the critical tables thoroughly" | ALL tables you build on are critical. If it's not worth full discovery, don't build models on it yet. |
| "Standard patterns, I know this data" | You know the pattern. This instance's data might vary. Verify with documentation or the user. |

## Red Flags - You're About to Skip Steps

Stop if you catch yourself:
- Reading only a column list without grain analysis
- Saying "the join should work" without checking documented relationships or asking about orphan records
- Noting "some nulls" without clarifying expected null behavior
- Planning to "document later"
- Feeling time pressure and reaching for shortcuts
- Treating a large table count as permission to be less thorough

**All of these mean: slow down, follow all 6 steps.**

## Large Scope Strategy

When facing many tables (20+), the answer is NOT abbreviated discovery. The answer is:

1. **Scope ruthlessly first** - Which tables will you actually build models on? Only those need discovery now.
2. **Full methodology on scoped tables** - Every table in scope gets all 6 steps. No exceptions.
3. **Explicit deferral for out-of-scope** - Document which tables you're NOT discovering and why. "Not needed for current project" is valid. "Too many tables" is not.

**Wrong approach:** "I'll do light discovery on all 47 tables"
**Right approach:** "I'll do full discovery on the 8 tables needed for this project"

## Core Method: Iterative Discovery

### Step 1: Inventory relevant objects

#### Sources

When discovering new raw data, review source YAML files and existing model references:

- Locate `sources:` definitions in `.yml` or `.yaml` files.
- Read source and table descriptions.
- Read column descriptions, tests, freshness settings, tags, and meta properties.
- Search SQL files for `source('source_name', 'table_name')` references to see how the source is already used.

#### Models

When previewing existing models, inspect the repository:

- Read the model SQL file.
- Read the colocated or related YAML file.
- Search for `ref('model_name')` references to understand usage.
- Review naming conventions and layer patterns before proposing changes.

### Step 2: Understand sample/raw data without execution

Use available repository artifacts first:

- Seeds or fixtures
- Unit test mock inputs and expected outputs
- Snapshots or static reference files
- Existing documentation and discovery notes
- SQL comments and YAML metadata

If those do not answer the question, ask the user for the specific missing information, such as:

- Column names and data types
- A small representative sample of rows
- Row counts and grain
- Null rates for important columns
- Distinct values for enum/status columns
- Primary key uniqueness and duplicate examples
- Relationship/orphan counts between tables

**Document immediately:**

- Column names and warehouse-native data types, if known
- Which columns appear to be identifiers vs attributes
- Known or uncertain null behavior
- Known low-cardinality values
- Any assumptions that require user confirmation

### Step 3: Clarify standard EDA questions

Do not run exploratory queries yourself. Instead, answer from SQL/YAML/test fixtures where possible and ask the user for missing results:

- What is the grain of the table?
- Are primary keys unique and non-null?
- Do date ranges make sense?
- What are the key column profiles?
- What foreign key relationships exist?
- Are there inconsistent data types or values in a column?

## Documenting Findings

Create a discovery report that other agents can consume. Place in a `data_discovery.md` file alongside the SQL/YAML files. Do not use Jinja in these discovery files to avoid them being mistaken for doc blocks.

### Discovery Report Template

```markdown
## Source: {source_name}.{table_name}

### Overview
- **Row count**: X or "unknown - requested from user"
- **Grain**: One row per [entity] per [time period]
- **Primary key**: column_name (verified from docs/tests or pending user confirmation)

### Column Analysis
| Column | Type | Nulls | Notes |
|--------|------|-------|-------|
| id | integer | 0% | Primary key |
| status | string | unknown | Ask user for valid values |
| created_at | timestamp | unknown | Confirm timezone and expected null behavior |

### Data Quality Questions
- [ ] Is `status = 'unknown'` valid or should it be mapped/filtered?
- [ ] Are negative `amount` values valid refunds or errors?

### Relationships
- `user_id` → `users.id` (status: documented / assumed / needs confirmation)
- `product_id` → `products.id` (status: documented / assumed / needs confirmation)

### Recommended Staging Transformations
1. Filter or map invalid statuses after stakeholder confirmation
2. Cast `created_at` to consistent timezone after timezone confirmation
3. Add surrogate key if natural key reliability is uncertain
```

## Common Mistakes

**Assuming column names reflect content**. Ask for samples or documentation; `customer_id` might contain account IDs.

**Not documenting findings**. Discovery without documentation wastes effort; write it down immediately.

**Assuming relationships are clean**. Orphan records may exist; ask for relationship counts if they affect model logic.

**Ignoring soft deletes**. Check for `deleted_at`, `is_active`, or `status` columns that filter valid records.
