FROM node:20-alpine AS builder
RUN apk add --no-cache libc6-compat
RUN npm install -g pnpm
WORKDIR /app

COPY pnpm-workspace.yaml pnpm-lock.yaml package.json turbo.json ./
COPY packages/types    ./packages/types
COPY packages/config   ./packages/config
COPY packages/db       ./packages/db
COPY services/api-gateway ./services/api-gateway

RUN pnpm install --frozen-lockfile
RUN pnpm --filter api-gateway build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs
RUN adduser  --system --uid 1001 appuser

COPY --from=builder --chown=appuser:nodejs /app/services/api-gateway/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages ./packages

USER appuser
EXPOSE 5001
CMD ["node", "dist/index.js"]
