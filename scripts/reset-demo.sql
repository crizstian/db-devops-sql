-- =============================================================================
-- RESET DEMO: Limpia todo para repetir la demo desde cero
-- =============================================================================
-- Uso: psql -h <host> -U <user> -d <database> -f scripts/reset-demo.sql
-- =============================================================================

-- 1. Eliminar schema de la aplicación (CASCADE elimina todas las tablas/views)
DROP SCHEMA IF EXISTS app CASCADE;

-- 2. Eliminar tablas de tracking de Liquibase (buscar en todos los schemas comunes)
DROP TABLE IF EXISTS public.databasechangelog CASCADE;
DROP TABLE IF EXISTS public.databasechangeloglock CASCADE;
DROP TABLE IF EXISTS public.test_pipeline_liquibase CASCADE;
DROP TABLE IF EXISTS public.test_pipeline_liquibase_2 CASCADE;
DROP TABLE IF EXISTS liquibase.databasechangelog CASCADE;
DROP TABLE IF EXISTS liquibase.databasechangeloglock CASCADE;
DROP TABLE IF EXISTS app.databasechangelog CASCADE;
DROP TABLE IF EXISTS app.databasechangeloglock CASCADE;

-- 3. Eliminar schema de Liquibase si existe separado
DROP SCHEMA IF EXISTS liquibase CASCADE;

-- 4. Recrear schema vacío para la demo
CREATE SCHEMA app;

-- 5. Confirmar reset
SELECT 'RESET COMPLETO' AS status, NOW() AS timestamp;
