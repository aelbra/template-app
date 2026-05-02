# =============================================================================
# Template Dockerfile — Node.js
#
# Roda direto de src/ (sem etapa de build). Quando o app tiver TypeScript ou
# bundler (esbuild/webpack/vite), troque pra um multi-stage com `npm run build`
# gerando dist/.
#
# Para .NET ver docs/dotnet.md.
# =============================================================================

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup -S app && adduser -S app -G app
COPY package*.json ./
RUN npm install --omit=dev && npm cache clean --force
COPY src/ ./src/
USER app
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --spider -q http://localhost:3000/health || exit 1
CMD ["node", "src/index.js"]
