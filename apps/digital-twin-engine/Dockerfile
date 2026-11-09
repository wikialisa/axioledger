FROM node:20-alpine AS pruner
RUN apk add --no-cache libc6-compat
RUN npm install -g turbo@latest
WORKDIR /app
COPY . .
ARG APP_NAME=digital-twin-engine
RUN turbo prune --scope=${APP_NAME} --docker

FROM node:20-alpine AS builder
RUN apk add --no-cache libc6-compat
RUN npm install -g pnpm
WORKDIR /app
COPY --from=pruner /app/out/json/ .
COPY --from=pruner /app/out/pnpm-lock.yaml ./pnpm-lock.yaml
RUN pnpm install --frozen-lockfile
COPY --from=pruner /app/out/full/ .
COPY turbo.json turbo.json
ARG APP_NAME=digital-twin-engine
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
RUN pnpm turbo run build --filter=${APP_NAME}...

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nodejs
RUN adduser  --system --uid 1001 appuser
ARG APP_NAME=digital-twin-engine
COPY --from=builder --chown=appuser:nodejs /app/apps/${APP_NAME}/dist ./dist
COPY --from=builder --chown=appuser:nodejs /app/apps/${APP_NAME}/package.json ./package.json
USER appuser
CMD ["node", "dist/index.js"]
