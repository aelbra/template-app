# CLAUDE.md — Convenções pro template-app (ULBRA Cloud)

Este arquivo orienta agentes IA (Claude, Copilot, etc) que trabalham neste repositório. Aplicações criadas a partir deste template devem manter este arquivo e adaptá-lo ao contexto do projeto.

## Stack padrão

- **Orquestração**: Docker Swarm (manager: `crmulbra`)
- **Reverse proxy**: Traefik v3.6, entrypoints `web/websecure/internal`
- **Observabilidade**: SigNoz (https://signoz.ulbra.ai) — traces/métricas/logs via OTel
- **Registry**: GHCR (`ghcr.io/aelbra/<repo>`)
- **CI/CD**: GitHub Actions com self-hosted runner `[self-hosted, ulbra]`

## Convenções obrigatórias

### Idioma
Português em commits, docs, comentários, nomes de arquivo e PRs. Acentuação correta.

### Branches
Padrão: `<usuario>/<sigla>-<numero>-<descricao-curta>`
Ex: `felipe-allmeida/ael-123-fix-login`, `joao-silva/ael-200-novo-endpoint`

### Commits e PRs
Formato: `tipo(SIGLA-NUMERO): descrição`

Tipos válidos: `feat`, `fix`, `chore`, `ci`, `refactor`, `docs`, `test`.

Exemplos:
- `feat(AEL-123): adicionar autenticação Google`
- `fix(AEL-145): corrigir leak de memória no cache`
- `docs(AEL-160): atualizar guia de deploy`

A primeira letra da primeira linha **deve ser maiúscula** (validado por hook).

Workflow `pr-title.yml` enforça esse regex:
```
^(feat|fix|chore|ci|refactor|docs|test)\([A-Z]+-[0-9]+\): .+
```

### Trunk-based development
Branch curta → PR → merge na main. Sem long-lived branches. Sem push direto na main.

### Secrets
- Nunca comitar `.env`, credenciais, tokens
- Usar GitHub Secrets / Variables para CI
- Docker Secrets para dados sensíveis em produção

## Docker / Compose

### Estrutura
- Compose de produção em `deploy/docker-compose.swarm.yml`
- Configs adicionais em `deploy/config/` se necessário
- Sempre 3 redes: `proxy` (external), `monitoring` (external), `internal` (overlay)

### Obrigatório em todo serviço
- `restart_policy: condition: any`
- `update_config` com `failure_action: rollback`, `order: start-first`
- `rollback_config` simétrico
- `resources.limits` (memory + cpus)
- `healthcheck` com `start_period`
- `logging: json-file, max-size: 10m, max-file: 3`

### OpenTelemetry — sempre ativo
Todo serviço de aplicação tem:
```yaml
environment:
  - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
  - OTEL_SERVICE_NAME=${APP_NAME}-<componente>
  - OTEL_RESOURCE_ATTRIBUTES=deployment.environment=${ENV_SLUG}
networks:
  - monitoring   # alcança o otel-collector via alias
```

### Traefik
Hostnames parametrizados via `${API_HOST}`/`${WEB_HOST}` definidos por GitHub Variables. Routers nomeados com `${ENV_SLUG}` pra não colidir entre ambientes na mesma instância do Traefik.

## Pipeline

| Trigger | Job | Ambiente |
|---|---|---|
| Push na main | build → deploy-dev (auto) | dev |
| `workflow_dispatch` + image_tag | deploy-staging | staging (com aprovação manual via Environments) |
| `workflow_dispatch` + image_tag | deploy-production | production (com aprovação manual) |

A tag da imagem é o **SHA curto do commit** — sempre prefira essa sobre `latest` em staging/prod (permite rollback fácil).

## Princípios

- **Aditivo, não destrutivo** — novas features convivem com o que já existe.
- **Trust internal code** — não validar o que o framework já garante; só validar entradas externas (user, APIs).
- **Sem comentários óbvios** — o código se explica; comentários só pra "porquê" não-óbvio.
- **Bug fix focado** — sem refactor de oportunidade junto.
- **Ambiente local primeiro** — testar antes de mexer em produção.

## Não fazer (regras de segurança)

- `--force`, `--hard`, `--no-verify` em git/docker
- `docker stack rm`, `docker volume rm`, `docker secret rm` sem autorização explícita
- `git reset --hard` ou `git push --force` sem autorização
- Alterar configs de serviços legados (CRM, MongoDB, etc no `crmulbra`)

## Observabilidade — onde olhar

| Painel | URL |
|---|---|
| SigNoz (APM, logs, traces) | https://signoz.ulbra.ai |
| Apps registradas (homepage) | https://apps.ulbra.ai |
| Traefik dashboard | https://traefik.ulbra.ai |
| GitHub Actions | https://github.com/aelbra/<repo>/actions |
