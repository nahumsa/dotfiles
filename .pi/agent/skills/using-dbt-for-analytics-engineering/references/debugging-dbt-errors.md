# How to debug dbt error messages

## Review logs and artifacts

If you are prompted to fix a bug, start by reviewing any logs, artifacts, or error messages already present in the repository or provided by the user.

- The `logs/dbt.log` file, if present, contains queries and logging from prior user-run invocations. Recent errors are usually near the bottom.
- The `target/run_results.json` file, if present, contains model outcomes from a prior user-run invocation.
- The `target/compiled` directory, if present, contains rendered model code as select statements.
- The `target/run` directory, if present, contains rendered code inside DDL statements such as `CREATE TABLE AS SELECT`.

If the error came from the console, ask the user to paste the error message if it is not already available.

The error messages dbt produces normally contain the type of error and the file where the error occurred.

## Classify and resolve the error

dbt project errors can have several root causes:

### Invalid dbt project configuration

These are likely to be YAML or parsing errors:

```text
error: dbt1013: YAML error: did not find expected key at line 14 column 7, while parsing a block mapping at line 11 column 5
  --> models/anchor_tests.yml:14:7
```

```text
Encountered an error:
Parsing Error
  Error reading jaffle_shop: anchor_tests.yml - Runtime Error
    Syntax error near line 14
```

These errors can be fixed by updating the impacted files, ensuring they conform to the correct YAML structure.

### Invalid model code

These are likely to be compilation or SQL errors, or a failing unit test:

```text
error: dbt1005: Found duplicate model 'my_first_model'
  --> models/my_first_model.sql
```

```text
error: dbt0101: mismatched input 'orders' expecting one of 'SELECT', 'TABLE', '('
  --> models/marts/customers.sql:9:1 (target/compiled/models/marts/customers.sql:9:1)
```

```text
03:16:39  Failure in unit_test test_does_location_opened_at_trunc_to_date (models/staging/stg_locations.yml)
03:16:39    

actual differs from expected:

@@,location_id,location_name,tax_rate,opened_date
  ,1          ,Vice City    ,0.2     ,2016-09-01 00:00:00
→ ,2          ,San Andreas  ,0.1     ,2079-10-27 00:00:00→2079-10-27 23:59:59.999900
```

These should be fixed by updating the referenced files in the error message. Fix invalid SQL, and ensure that the transformations produce the desired output based on defined tests and documentation.

### Invalid data

Invalid data may be reported by a user-run test/build or by stakeholder reports.

```text
03:29:09  Failure in test accepted_values_customers_customer_type__new__returning (models/marts/customers.yml)
03:29:09    Got 1 result, configured to fail if != 0
03:29:09  
03:29:09    compiled code at target/compiled/jaffle_shop/models/marts/customers.yml/accepted_values_customers_customer_type__new__returning.sql
```

It normally needs to be resolved by transforming the underlying data to match the test's expectations. Perform transformations as early in the DAG as possible, ideally in a staging layer.

Do not remove a test, or modify a test to pass, without explicit permission.

If the invalid data details are not available, ask the user for representative failing rows, counts, distinct values, or a description of the expected business rule.

## Check that the error is resolved

After making project changes, do not execute validation tooling yourself. Instead:

- Re-read the edited SQL/YAML for syntax and consistency with existing patterns.
- Compare changes against the error message, compiled SQL artifact, or failing test fixture if available.
- State what you changed and what user-side validation is recommended.
- Ask the user for any new error output if their validation still fails.
