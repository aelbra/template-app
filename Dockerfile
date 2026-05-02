# =============================================================================
# Template Dockerfile — Node.js
# Ajuste conforme a linguagem do projeto. Para .NET ver docs/dotnet.md.
# =============================================================================

FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build --if-present

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup -S app && adduser -S app -G app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./
USER app
EXPOSE 3000
CMD ["node", "dist/index.js"]
