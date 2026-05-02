# Primeiro deploy

Passo a passo pra colocar uma app nova criada a partir deste template no ar.

## 1. Renomear o template no código

O template usa `${APP_NAME}` em vários lugares — vai ser substituído via GitHub Variables (passo 3), você não precisa editar arquivos manualmente.

Mas confira se quer ajustar:

- `package.json` — campo `"name"` (não tem impacto runtime, só convenção)
- `Dockerfile` — porta exposta (`EXPOSE 3000`) se a sua app rodar em outra
- `deploy/docker-compose.swarm.yml` — descomenta blocos `web` e/ou `postgres` se precisar

## 2. Configurar DNS

Pede pro pessoal de TI (Marcos) criar os registros A apontando pro IP público do servidor `crmulbra`:

| Hostname | Aponta para | Quando |
|---|---|---|
| `<app>-dev.ulbra.ai` | 187.60.192.201 | sempre |
| `<app>-staging.ulbra.ai` | 187.60.192.201 | se tiver staging |
| `<app>.ulbra.ai` | 187.60.192.201 | em prod |

Se já existe wildcard `*.ulbra.ai`, não precisa criar nada — só esperar propagar.

## 3. Configurar GitHub Variables

Em **Settings → Secrets and variables → Actions → Variables**, criar:

| Variable | Exemplo | Quando |
|---|---|---|
| `APP_NAME` | `meu-app` | sempre (kebab-case, será usado em traefik routers e service names) |
| `API_HOST_DEV` | `meu-app-dev.ulbra.ai` | sempre |
| `API_HOST_STAGING` | `meu-app-staging.ulbra.ai` | se tiver staging |
| `API_HOST_PROD` | `meu-app.ulbra.ai` | em prod |

## 4. Configurar Environments (proteção de prod)

Em **Settings → Environments**, criar 3 environments: `dev`, `staging`, `production`.

Pra `staging` e `production`, marcar **"Required reviewers"** com sua pessoa (ou um time). Isso faz o deploy esperar aprovação manual.

> Requer GitHub Team plan ou superior. Se não tiver, deploy passa direto sem aprovação — equivalente a confiar no `workflow_dispatch` manual.

## 5. Self-hosted runner

Os jobs usam `runs-on: [self-hosted, ulbra]` — o runner já existe na org `aelbra` (registrado no servidor `crmulbra`). Se o repo for novo, garante que ele tem permissão pra usar o runner em **Settings → Actions → Runners**.

## 6. Push inicial

```bash
git add .
git commit -m "Feat(AEL-XXX): scaffold inicial baseado no template"
git push origin main
```

Vai disparar:
1. **build** — buildar imagem Docker e fazer push pro GHCR taggeada com SHA curto + `latest`
2. **deploy-dev** — `docker stack deploy` em `<app>-dev` no servidor

Acompanha em **Actions** no GitHub.

## 7. Verificar

```bash
ssh crmulbra
sudo docker stack services <app>-dev
sudo docker service logs <app>-dev_api --tail 50
```

E no navegador:

- `https://<app>-dev.ulbra.ai/health` → `{"status":"ok"}`
- https://signoz.ulbra.ai → service `<app>-api` aparece em ~1min com `deployment.environment=dev`

## 8. Promover pra staging/prod

Em **Actions → Deploy → Run workflow**:

- **promover para**: staging ou production
- **image_tag**: SHA curto que tá em dev (pega de uma execução anterior do build) — em prod é obrigatório, em staging fica `latest` se vazio

## Troubleshooting

### O serviço sobe mas a rota não funciona
- Cert do Let's Encrypt demora ~30s no primeiro request
- DNS não propagou ainda (`dig <hostname>`)
- Label `traefik.docker.network=proxy` está presente?

### O serviço fica em crashloop
- `docker service logs <stack>_<svc> --tail 50`
- Healthcheck do compose batendo no path errado?
- Falta `monitoring` na lista de redes? (OTel SDK falha se não conseguir conectar no `otel-collector:4317`)

### Não aparece no SigNoz
- Confere se o app instanciou o SDK (`require('./otel')` é o **primeiro** require em Node)
- Confere se está na rede `monitoring`
- Em dev, dispara um request pra forçar geração de telemetria
