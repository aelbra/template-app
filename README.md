# Template App — ULBRA Cloud

Template para criar novas aplicações no datacenter da ULBRA.

## Como usar

1. Criar novo repo a partir deste template (botão **"Use this template"** no GitHub)
2. Substituir `NOME_DO_APP` em todos os arquivos pelo nome da sua aplicação
3. Ajustar o `Dockerfile` para a linguagem/framework do projeto
4. Ajustar a porta no `docker-compose.yml` e no healthcheck
5. Push na main — deploy automático em dev

## Arquivos

| Arquivo | O que faz |
|---|---|
| `Dockerfile` | Como buildar a imagem Docker |
| `docker-compose.yml` | Stack para Docker Swarm com labels do Traefik |
| `.github/workflows/deploy.yml` | Pipeline CI/CD (dev/staging/prod) |

## Ambientes

| Ambiente | Trigger | Rota |
|---|---|---|
| Dev | Push na main (automático) | `dev.NOME_DO_APP.ulbra.internal` |
| Staging | Botão manual no GitHub Actions | `staging.NOME_DO_APP.ulbra.internal` |
| Production | Botão manual no GitHub Actions | `NOME_DO_APP.ulbra.internal` |

## Pipeline

```
Push na main → Build imagem → Deploy DEV (automático)
                                  │
                    GitHub Actions > Run workflow
                                  │
                         ├── staging (manual)
                         └── production (manual)
```

## Variáveis de ambiente

Configurar no `docker-compose.yml`:

- `NODE_ENV` — ambiente (development/production)
- `OTEL_EXPORTER_OTLP_ENDPOINT` — endpoint do OpenTelemetry (já configurado)
- `OTEL_SERVICE_NAME` — nome do serviço no monitoring

## Monitoring

Métricas, logs e traces são coletados automaticamente:

- **Grafana**: http://172.18.152.201:3001
- **Logs**: Grafana > Explore > Loki > `{compose_service="NOME_DO_APP"}`
- **Métricas**: via OpenTelemetry (adicionar SDK ao projeto)
