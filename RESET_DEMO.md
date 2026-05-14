# Reset Demo - Guía Rápida

## Paso 1: Reset Base de Datos

```bash
# Opción A: Desde Cloud SQL (GCP)
gcloud sql connect <INSTANCE_NAME> --user=postgres --database=<DB_NAME>
\i scripts/reset-demo.sql

# Opción B: Desde psql directo
psql -h <HOST> -U postgres -d <DB_NAME> -f scripts/reset-demo.sql

# Opción C: Comando inline
psql -h <HOST> -U postgres -d <DB_NAME> -c "
  DROP SCHEMA IF EXISTS app CASCADE;
  DROP TABLE IF EXISTS public.databasechangelog CASCADE;
  DROP TABLE IF EXISTS public.databasechangeloglock CASCADE;
  CREATE SCHEMA app;
"
```

**Resultado esperado:**
```
DROP SCHEMA
DROP TABLE
DROP TABLE
CREATE SCHEMA
    status     |          timestamp
---------------+------------------------------
 RESET COMPLETO | 2026-05-14 10:00:00.000000
```

---

## Paso 2: Reset Harness DB DevOps Schema

### En UI de Harness:

1. Ir a **DB DevOps** → **Schemas**
2. Seleccionar el schema de la demo
3. Click **⋮** (menú) → **Delete**
4. Confirmar eliminación
5. Click **+ New Schema** → recrear con misma configuración:
   - Name: `demo-liquibase`
   - Connector: (tu conector PostgreSQL)
   - Database: (tu base de datos)

### Vía API (opcional):

```bash
# Eliminar schema
curl -X DELETE "https://app.harness.io/gateway/dbops/api/v1/orgs/${ORG}/projects/${PROJECT}/schemas/${SCHEMA_ID}" \
  -H "x-api-key: ${HARNESS_API_KEY}"

# Recrear requiere POST con el body de configuración
```

---

## Checklist Pre-Demo

- [ ] Reset DB ejecutado (`scripts/reset-demo.sql`)
- [ ] Schema en Harness eliminado y recreado
- [ ] Branch `main` limpio (sin PRs pendientes)
- [ ] Pipeline `db-devops` visible en Harness
- [ ] Crear branch nuevo para demo: `git checkout -b demo-$(date +%Y%m%d)`

---

## Tiempo estimado: 2-3 minutos
