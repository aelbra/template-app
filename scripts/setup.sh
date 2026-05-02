#!/usr/bin/env bash
# =============================================================================
# Bootstrap pós-clone do template.
# Renomeia placeholders, cria commit inicial.
# =============================================================================
set -euo pipefail

read -rp "Nome da app (kebab-case, ex: meu-app): " APP_NAME
read -rp "Sigla do projeto Linear (ex: AEL): " SIGLA
read -rp "Número do issue inicial (ex: 100): " ISSUE_NUM

if [[ -z "$APP_NAME" || -z "$SIGLA" || -z "$ISSUE_NUM" ]]; then
  echo "Todos os campos são obrigatórios." >&2
  exit 1
fi

# Atualiza package.json
sed -i.bak "s/\"name\": \"template-app\"/\"name\": \"$APP_NAME\"/" package.json && rm package.json.bak

# Atualiza README e CLAUDE.md
for f in README.md CLAUDE.md; do
  sed -i.bak "s/template-app/$APP_NAME/g" "$f" && rm "$f.bak"
done

echo "[OK] Placeholders renomeados para '$APP_NAME'."
echo ""
echo "Próximos passos:"
echo "  1. Configurar GitHub Variables (ver docs/primeiro-deploy.md)"
echo "  2. git add . && git commit -m 'Feat($SIGLA-$ISSUE_NUM): scaffold inicial'"
echo "  3. git push origin main"
