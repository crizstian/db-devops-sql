A continuación te dejo un resumen detallado, pensado como briefing para otro asistente (Claude) sobre **todo el ejercicio que hicimos con Liquibase**, la **estructura de archivos** y el **flujo tipo tutorial** que construimos.

***

## 1. Contexto general del ejercicio

- Base de datos: **PostgreSQL en Cloud SQL (GCP)**.
- Objetivo: montar una **POC de Database DevOps** usando:
  - Liquibase como motor de versionamiento de BD.
  - Estructura de changelogs en YAML (no XML).
  - Scripts DDL/DML/rollback en SQL separados.
  - Pipelines (conceptuales) orquestados luego con Harness DB DevOps.
- Esquema / tablas de ejemplo:
  - Inicialmente trabajamos con tablas `test_pipeline_liquibase` y `test_pipeline_liquibase_2`.
  - En un segundo diseño más “DBA friendly” usamos esquema `app` con tablas `app.customer` y `app.country`.

***

## 2. Estructura de archivos de Liquibase

El usuario definió una estructura **sin carpeta `liquibase`** y usando rutas cortas:

```text
db/
  changelog-master.yaml
  changelog/
    001-00-init-schema.yaml
    002-00-add-column-customer.yaml
    003-00-seed-reference-data.yaml
    004-00-drop-column-email.yaml
    005-00-create-index-email.yaml
    006-00-rename-column-name-fullname.yaml
    007-00-create-view-customer_country.yaml
    008-00-update-customer-email-domain.yaml
  scripts/
    ddl/
      001-00-01-create-schema-and-tables.sql
      002-00-01-add-column-customer_email.sql
      004-00-01-drop-column-customer_email.sql
      005-00-01-create-index-customer_email.sql
      006-00-01-rename-column-name-full_name.sql
      007-00-01-create-view-customer_country.sql
    dml/
      003-00-01-insert-country-reference.sql
      008-00-01-update-email-domain.sql
    rollback/
      001-00/001-00-01-rollback.sql
      002-00/002-00-01-rollback.sql
      003-00/003-00-01-rollback.sql
      004-00/004-00-01-rollback.sql
      005-00/005-00-01-rollback.sql
      006-00/006-00-01-rollback.sql
      007-00/007-00-01-rollback.sql
      008-00/008-00-01-rollback.sql
```

### 2.1. Changelog maestro

`changelog-master.yaml` actúa como **fuente de verdad**:

```yaml
databaseChangeLog:
  - include:
      file: changelog/001-00-init-schema.yaml
  - include:
      file: changelog/002-00-add-column-customer.yaml
  - include:
      file: changelog/003-00-seed-reference-data.yaml
  - include:
      file: changelog/004-00-drop-column-email.yaml
  - include:
      file: changelog/005-00-create-index-email.yaml
  - include:
      file: changelog/006-00-rename-column-name-fullname.yaml
  - include:
      file: changelog/007-00-create-view-customer_country.yaml
  - include:
      file: changelog/008-00-update-customer-email-domain.yaml
```

- **Todo nuevo caso de uso** implica:
  - Crear un nuevo `changelog/XXX-YY-...yaml`.
  - Crear sus scripts SQL.
  - Añadir un `include` al `changelog-master.yaml`.

***

## 3. Convención de nombrado

Se definió una convención numérica tipo:

- `001-00`, `002-00`, `002-00-01`, etc. para **features / cambios**.
- Sufijo `-change_desc.yaml` (en la primera versión) o nombre descriptivo corto (`init-schema`, `add-column-customer`).
- Esto da:
  - Orden lógico y cronológico.
  - Evitar colisiones entre equipos.
  - Trazabilidad clara hacia historias / features.

***

## 4. Casos de uso Liquibase (POC)

Se configuró un conjunto de casos de uso que cubren:

1. **Versionamiento de estructura**
2. **Rollbacks**
3. **Creación de esquema**
4. **Cambios de esquema (ALTER)**
5. **Inserción / actualización de datos**
6. **Auditoría**
7. **Flujo de aprobación (conceptual, luego mapeado a Harness)**

### 4.1. Caso 001-00 – Crear esquema y tabla base

**Changelog**: `changelog/001-00-init-schema.yaml`

```yaml
databaseChangeLog:
  - changeSet:
      id: 001-00
      author: carrramirez
      context: state:feature
      changes:
        - sqlFile:
            path: scripts/ddl/001-00-01-create-schema-and-tables.sql
      rollback:
        - sqlFile:
            path: scripts/rollback/001-00/001-00-01-rollback.sql
```

**DDL**: `scripts/ddl/001-00-01-create-schema-and-tables.sql`

```sql
CREATE SCHEMA IF NOT EXISTS app;

CREATE TABLE app.customer (
    id          BIGSERIAL PRIMARY KEY,
    name        TEXT        NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE app.customer IS 'Customer master table for application POC';
COMMENT ON COLUMN app.customer.name IS 'Customer display name';
```

**Rollback**: `scripts/rollback/001-00/001-00-01-rollback.sql`

```sql
DROP TABLE IF EXISTS app.customer;
DROP SCHEMA IF EXISTS app;
```

### 4.2. Caso 002-00 – Cambio de esquema (ADD COLUMN)

`changelog/002-00-add-column-customer.yaml`:

```yaml
databaseChangeLog:
  - changeSet:
      id: 002-00
      author: carrramirez
      context: state:feature
      changes:
        - sqlFile:
            path: scripts/ddl/002-00-01-add-column-customer_email.sql
      rollback:
        - sqlFile:
            path: scripts/rollback/002-00/002-00-01-rollback.sql
```

`002-00-01-add-column-customer_email.sql`:

```sql
ALTER TABLE app.customer
ADD COLUMN email TEXT;

COMMENT ON COLUMN app.customer.email IS 'Customer email address (nullable during POC)';
```

Rollback:

```sql
ALTER TABLE app.customer
DROP COLUMN IF EXISTS email;
```

### 4.3. Caso 003-00 – Insert de datos de referencia

`changelog/003-00-seed-reference-data.yaml`:

```yaml
databaseChangeLog:
  - changeSet:
      id: 003-00
      author: carrramirez
      context: state:feature
      changes:
        - sqlFile:
            path: scripts/dml/003-00-01-insert-country-reference.sql
      rollback:
        - sqlFile:
            path: scripts/rollback/003-00/003-00-01-rollback.sql
```

DML:

```sql
CREATE TABLE IF NOT EXISTS app.country (
    code CHAR(2) PRIMARY KEY,
    name TEXT NOT NULL
);

INSERT INTO app.country (code, name) VALUES
    ('MX', 'Mexico'),
    ('US', 'United States'),
    ('CA', 'Canada')
ON CONFLICT (code) DO NOTHING;
```

Rollback:

```sql
DELETE FROM app.country
WHERE code IN ('MX', 'US', 'CA');
```

### 4.4. Caso 004-00 – Drop column con rollback

`changelog/004-00-drop-column-email.yaml`:

```yaml
databaseChangeLog:
  - changeSet:
      id: 004-00
      author: carrramirez
      context: state:feature
      changes:
        - sqlFile:
            path: scripts/ddl/004-00-01-drop-column-customer_email.sql
      rollback:
        - sqlFile:
            path: scripts/rollback/004-00/004-00-01-rollback.sql
```

DROP:

```sql
ALTER TABLE app.customer
DROP COLUMN IF EXISTS email;
```

Rollback (recrear columna):

```sql
ALTER TABLE app.customer
ADD COLUMN email TEXT;

COMMENT ON COLUMN app.customer.email IS 'Customer email address (recreated after rollback of drop column)';
```

### 4.5. Caso 005-00 – Crear índice

Changelog:

```yaml
databaseChangeLog:
  - changeSet:
      id: 005-00
      author: carrramirez
      context: state:feature
      changes:
        - sqlFile:
            path: scripts/ddl/005-00-01-create-index-customer_email.sql
      rollback:
        - sqlFile:
            path: scripts/rollback/005-00/005-00-01-rollback.sql
```

DDL:

```sql
CREATE INDEX IF NOT EXISTS idx_customer_email
ON app.customer (email);
```

Rollback:

```sql
DROP INDEX IF EXISTS idx_customer_email;
```

### 4.6. Caso 006-00 – Renombrar columna

```yaml
databaseChangeLog:
  - changeSet:
      id: 006-00
      author: carrramirez
      context: state:feature
      changes:
        - sqlFile:
            path: scripts/ddl/006-00-01-rename-column-name-full_name.sql
      rollback:
        - sqlFile:
            path: scripts/rollback/006-00/006-00-01-rollback.sql
```

```sql
ALTER TABLE app.customer
RENAME COLUMN name TO full_name;
```

Rollback:

```sql
ALTER TABLE app.customer
RENAME COLUMN full_name TO name;
```

### 4.7. Caso 007-00 – Crear vista

```yaml
databaseChangeLog:
  - changeSet:
      id: 007-00
      author: carrramirez
      context: state:feature
      changes:
        - sqlFile:
            path: scripts/ddl/007-00-01-create-view-customer_country.sql
      rollback:
        - sqlFile:
            path: scripts/rollback/007-00/007-00-01-rollback.sql
```

```sql
CREATE OR REPLACE VIEW app.vw_customer_country AS
SELECT
  c.id,
  c.full_name,
  c.email,
  c.created_at,
  ct.code  AS country_code,
  ct.name  AS country_name
FROM app.customer c
LEFT JOIN app.country ct
  ON c.country_code = ct.code;
```

Rollback:

```sql
DROP VIEW IF EXISTS app.vw_customer_country;
```

### 4.8. Caso 008-00 – Update de datos con backup + rollback

```yaml
databaseChangeLog:
  - changeSet:
      id: 008-00
      author: carrramirez
      context: state:feature
      changes:
        - sqlFile:
            path: scripts/dml/008-00-01-update-email-domain.sql
      rollback:
        - sqlFile:
            path: scripts/rollback/008-00/008-00-01-rollback.sql
```

DML con backup:

```sql
CREATE TABLE IF NOT EXISTS app.customer_email_backup AS
SELECT id, email
FROM app.customer
WHERE email LIKE '%@oldcorp.com';

UPDATE app.customer
SET email = regexp_replace(email, '@oldcorp\.com$', '@newcorp.com')
WHERE email LIKE '%@oldcorp.com';
```

Rollback:

```sql
UPDATE app.customer c
SET email = b.email
FROM app.customer_email_backup b
WHERE c.id = b.id;

-- Opcional:
-- DROP TABLE IF EXISTS app.customer_email_backup;
```

***

## 5. Comandos estándar usados en el tutorial

### 5.1. Liquibase

- Validar sin aplicar cambios:

```bash
liquibase --changeLogFile=db/changelog-master.yaml validate
```

- Aplicar cambios (update) usando context:

```bash
liquibase \
  --changeLogFile=db/changelog-master.yaml \
  --contexts=state:feature \
  update
```

- Rollback de últimos N cambios:

```bash
liquibase \
  --changeLogFile=db/changelog-master.yaml \
  rollbackCount N
```

### 5.2. Validación y reset desde SQL

Validar estructura:

```sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'app'
ORDER BY table_name;
```

Validar datos:

```sql
SELECT COUNT(*) FROM app.customer;
SELECT COUNT(*) FROM app.country;
```

Reset suave de datos:

```sql
TRUNCATE TABLE app.customer RESTART IDENTITY CASCADE;
TRUNCATE TABLE app.country RESTART IDENTITY CASCADE;
DROP TABLE IF EXISTS app.customer_email_backup;
```

Reset completo de esquema:

```sql
DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
```

***

## 6. Extensión conceptual a Harness DB DevOps (alto nivel)

Aunque no se implementó YAML real de Harness en detalle, sí se definió el flujo conceptual:

1. Dev/DBA hace PR con nuevos cambios Liquibase.
2. Pipeline de Harness DB DevOps:
   - Step de **Validate** (Liquibase).
   - Step de **Policy/OPA** (gobernanza; por ejemplo bloquear `DROP TABLE` en prod).
   - Step de **Apply** (Liquibase update).
3. Pipeline de rollback:
   - Step de Policy (opcional).
   - Step de **Rollback** (rollbackCount o por changeset/tag).
4. Auditoría combinando:
   - `DATABASECHANGELOG`.
   - Historial de ejecuciones en Harness.
   - Git (PRs, commits, tags).

***

Este resumen te da todo el contexto: estructura de repo, casos de uso, contenido de archivos Liquibase y el flujo de validación/reset que se fue usando durante la POC.