CREATE TABLE test_pipeline_liquibase (
    id SERIAL PRIMARY KEY,
    description TEXT NOT NULL
);
COMMENT ON TABLE test_pipeline_liquibase IS 'Tabla para pruebas Liquibase (caso 001-00)';
COMMENT ON COLUMN test_pipeline_liquibase.description IS 'Descripción del registro';
