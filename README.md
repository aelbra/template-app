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
| Dev | Push na main (automático) | `dev.NOME_DO_APP.ulbra.ai` |
| Staging | Botão manual no GitHub Actions | `staging.NOME_DO_APP.ulbra.ai` |
| Production | Botão manual no GitHub Actions | `NOME_DO_APP.ulbra.ai` |

## Pipeline

```
Push na main → Build imagem → Deploy DEV (automático)
                                  │
                    GitHub Actions > Run workflow
                                  │
                         ├── staging (manual)
                         └── production (manual)
```

## Roteamento (Traefik)

Os serviços rodam atrás do Traefik com 2 entrypoints:

- **websecure** (:443) — HTTPS público (com cert do Let's Encrypt)
- **internal** (:8081) — só pela VPN da ULBRA

A label `tls.certresolver=letsencrypt` faz o Traefik pedir cert automaticamente. O cert é emitido em ~30s no primeiro request e renovado a cada 60 dias.

### Apps internos (sem acesso externo)

Se o app for só pra uso interno, troca:

```yaml
- "traefik.http.routers.NOME_DO_APP.entrypoints=internal"
# remove tls=true e tls.certresolver
```

## Variáveis de ambiente

Configurar no `docker-compose.yml`:

- `NODE_ENV` — ambiente (development/production)
- `OTEL_EXPORTER_OTLP_ENDPOINT` — endpoint do OpenTelemetry (já configurado)
- `OTEL_SERVICE_NAME` — nome do serviço no monitoring

## Monitoring

Métricas, logs e traces são coletados automaticamente:

- **Grafana**: https://grafana.ulbra.ai (interno)
- **Logs**: Grafana > Explore > Loki > `{service=~".*NOME_DO_APP.*"}`
- **Métricas**: via OpenTelemetry (adicionar SDK ao projeto)
