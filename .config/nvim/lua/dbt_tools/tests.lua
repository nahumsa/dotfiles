-- Backwards-compatible alias. This module does not run tests; it only annotates
-- dbt SQL buffers with test declarations from YAML metadata.
return require("dbt_tools.test_annotations")
