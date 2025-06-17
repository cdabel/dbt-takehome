{% macro union_tenant_tables(seed_table_name) %}
  -- In this take-home, all tenant data is already in one flat CSV with a schema_name column
  SELECT * FROM {{ ref(seed_table_name) }}
{% endmacro %}
