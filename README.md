# template-app — ULBRA Cloud

Template oficial para novas aplicações no datacenter da ULBRA. Já vem configurado com:

- **Docker Swarm** multi-ambiente (dev/staging/prod)
- **Traefik** com TLS Let's Encrypt e roteamento por hostname
- **OpenTelemetry → SigNoz** (traces, métricas, logs)
- **CI/CD** via GitHub Actions (build no push, promoção manual)
- **Validação de PR title** (regex `tipo(AEL-NNN): descrição`)

## Como usar

1. Clica em **"Use this template"** no GitHub
2. Roda `bash scripts/setup.sh` (renomeia placeholder, faz commit inicial) — _ou_ segue o passo a passo em [`docs/primeiro-deploy.md`](docs/primeiro-deploy.md)
3. Configura as **GitHub Variables** do repo (ver `docs/primeiro-deploy.md`)
4. Push na main → deploy automático em dev em https://`${APP_NAME}-dev.ulbra.ai`

## Estrutura

```
.
├── .github/workflows/      # CI, deploy, pr-title
├── deploy/
│   └── docker-compose.swarm.yml   # stack do Swarm (3 redes, OTel, multi-env)
├── docs/
│   ├── primeiro-deploy.md  # passo a passo de configuração
│   └── dotnet.md           # como adaptar pra .NET
├── src/
│   ├── otel.js             # bootstrap OpenTelemetry
│   └── index.js            # entrypoint placeholder
├── Dockerfile              # multi-stage Node
├── package.json
├── CLAUDE.md               # convenções pra agentes IA
└── README.md
```

## Pipeline

```
push na main → build imagem → deploy DEV (automático)
                                 │
                       Actions ▸ Run workflow
                                 │
                  ├── promover staging (manual + image_tag)
                  └── promover production (manual + image_tag)
```

## Observabilidade

Telemetria sai automaticamente pra https://signoz.ulbra.ai. O serviço aparece como `${APP_NAME}-api` separado por `deployment.environment` (dev/staging/prod).

Pra adicionar métricas customizadas em Node:

```js
const { metrics } = require('@opentelemetry/api');
const meter = metrics.getMeter('myapp');
const counter = meter.createCounter('myapp.requests.total');
counter.add(1, { route: '/foo' });
```

## Convenções

- **Branch**: `<usuario>/<sigla>-<numero>-<descricao>` (ex: `felipe-allmeida/ael-123-fix-login`)
- **Commit/PR**: `tipo(SIGLA-NUMERO): descrição` (ex: `feat(AEL-123): adicionar login`)
- **Idioma**: português (commits, docs, comentários)

Mais detalhes em [`CLAUDE.md`](CLAUDE.md).
