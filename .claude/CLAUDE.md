# Contexto del Proyecto

## Arquitectura MCP Gateway (Modo Estático)

```
HOST (Mac)                                    DEVCONTAINER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Docker Compose (mcp-gateway/)                 .mcp.json
│                                                 │
├── mcp-gateway (:8811 SSE) ◄─────────────────────┘
│   └── --static=true
│   └── --servers=github,kubernetes,filesystem,perplexity-ask,harness
│
├── mcp-github        (mcp/github)
├── mcp-kubernetes    (mcp/kubernetes)      ←── ~/.kube mount
├── mcp-filesystem    (mcp/filesystem)
├── mcp-perplexity    (mcp/perplexity-ask)
└── mcp-harness       (node:20-alpine + npx)

.env (secrets)
```

Ver [mcp-gateway/README.md](mcp-gateway/README.md) para documentación completa.

---

## Reglas de Selección de Herramientas

### Orden de Preferencia

| Prioridad | Tipo | Cuándo usar |
|-----------|------|-------------|
| 1 | MCP Server | Siempre primero si existe |
| 2 | CLI dedicado | Operaciones rápidas (gh, kubectl, gcloud) |
| 3 | REST API | Solo si MCP no disponible |

### Por Dominio

| Dominio | Principal | Fallback |
|---------|-----------|----------|
| CI/CD | harness MCP | REST API |
| GitHub | github MCP | gh CLI |
| Kubernetes | kubernetes MCP | kubectl |
| Búsqueda web | perplexity-ask MCP | WebSearch builtin |
| Archivos locales | filesystem MCP | Read/Write tools |

---

## Harness CI/CD

### Reglas de Comportamiento

1. **Antes de ejecutar pipeline**, verificar estado
2. **Después de ejecutar**, monitorear ejecución
3. **Si falla**, obtener logs para diagnóstico
4. **Nunca eliminar recursos** sin confirmación explícita

### Variables (configuradas en mcp-gateway/.env)

```
HARNESS_API_KEY
HARNESS_ACCOUNT_ID
HARNESS_ORG
HARNESS_PROJECT
HARNESS_BASE_URL
```

---

## GitHub

- `git` → operaciones locales: status, diff, branch, commit
- `gh` → CLI rápido: PR status, issue view
- `github MCP` → operaciones estructuradas sobre PRs, issues, repos

### Antes de crear PR

1. `git diff --stat`
2. Ejecutar tests
3. Crear PR con título y descripción claros

**No cerrar issues ni hacer merge sin instrucción explícita.**

---

## Búsqueda Web

### Reglas

1. **Primero**: perplexity-ask MCP
2. **Solo sin herramientas**: Si la respuesta está en contexto local

### Cuando uses Perplexity

- Query clara y específica
- Resumir hallazgos relevantes
- Indicar si información puede cambiar

---

## Stack

- Go (golang:alpine)
- Kubernetes (kubectl via mount ~/.kube)
- Google Cloud (gcloud via mount ~/.config/gcloud)
- AWS (aws-cli via mount ~/.aws)

---

## Troubleshooting MCP Gateway

### Gateway no responde

```bash
# En HOST (Mac):
cd mcp-gateway
make status
make logs
make restart
```

### Agregar nuevo server

1. Agregar servicio a `mcp-gateway/docker-compose.yml`:

```yaml
  mcp-nuevo-server:
    image: mcp/nuevo-server
    container_name: mcp-nuevo-server
    restart: unless-stopped
    init: true
    stdin_open: true
    tty: true
    environment:
      - VARIABLE_REQUERIDA=${VARIABLE_REQUERIDA}
    labels:
      - docker-mcp=true
      - docker-mcp-name=nuevo-server
      - docker-mcp-transport=stdio
```

2. Agregar a `--servers` del gateway:

```yaml
    command:
      - --servers=github,...,nuevo-server
```

3. Agregar a `.env`:

```
VARIABLE_REQUERIDA=valor
```

4. Reiniciar:

```bash
make down && make up
```

### Verificar config

```bash
make status      # Ver estado
make test        # Test health
make logs        # Ver logs
make validate    # Validar sintaxis
```

---

## Onboarding (nueva laptop)

```bash
# 1. Docker Desktop instalado
# 2. Clonar repo
# 3. cd mcp-gateway
# 4. cp .env.example .env && chmod 600 .env
# 5. Editar .env con tus secrets
# 6. make up
# 7. make test
# 8. Copiar templates/.mcp.json a cada proyecto
# 9. Abrir proyecto en VSCode con DevContainer
# 10. /mcp para verificar
```

Ver [mcp-gateway/README.md](mcp-gateway/README.md) para guía completa.
