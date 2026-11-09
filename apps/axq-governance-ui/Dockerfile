FROM node:26-alpine AS pruner
RUN apk add --no-cache libc6-compat
RUN npm install -g turbo@latest
WORKDIR /app
COPY . .
ARG APP_NAME=axq-governance-ui
RUN turbo prune --scope=${APP_NAME} --docker

FROM node:26-alpine AS builder
RUN apk add --no-cache libc6-compat
RUN npm install -g pnpm
WORKDIR /app
COPY --from=pruner /app/out/json/ .
COPY --from=pruner /app/out/pnpm-lock.yaml ./pnpm-lock.yaml
RUN pnpm install --frozen-lockfile
COPY --from=pruner /app/out/full/ .
COPY turbo.json turbo.json
ARG APP_NAME=axq-governance-ui
ARG NEXT_PUBLIC_API_URL
ARG NEXT_PUBLIC_NETWORK
ARG NEXT_PUBLIC_CHAIN_ID
ARG NEXT_PUBLIC_RPC_URL
ARG NEXT_PUBLIC_AXQ_TOKEN
ARG NEXT_PUBLIC_ANS_REGISTRY
ARG NEXT_PUBLIC_AXQ_GOVERNANCE
ARG NEXT_PUBLIC_VRQ_VALIDATOR
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
ENV NEXT_PUBLIC_NETWORK=${NEXT_PUBLIC_NETWORK}
ENV NEXT_PUBLIC_CHAIN_ID=${NEXT_PUBLIC_CHAIN_ID}
ENV NEXT_PUBLIC_RPC_URL=${NEXT_PUBLIC_RPC_URL}
ENV NEXT_PUBLIC_AXQ_TOKEN=${NEXT_PUBLIC_AXQ_TOKEN}
ENV NEXT_PUBLIC_ANS_REGISTRY=${NEXT_PUBLIC_ANS_REGISTRY}
ENV NEXT_PUBLIC_AXQ_GOVERNANCE=${NEXT_PUBLIC_AXQ_GOVERNANCE}
ENV NEXT_PUBLIC_VRQ_VALIDATOR=${NEXT_PUBLIC_VRQ_VALIDATOR}
RUN pnpm turbo run build --filter=${APP_NAME}...

FROM node:26-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nodejs
RUN adduser  --system --uid 1001 appuser
ARG APP_NAME=axq-governance-ui
COPY --from=builder /app/apps/${APP_NAME}/public             ./public
COPY --from=builder --chown=appuser:nodejs \
     /app/apps/${APP_NAME}/.next/standalone ./
COPY --from=builder --chown=appuser:nodejs \
     /app/apps/${APP_NAME}/.next/static      ./.next/static
USER appuser
EXPOSE 3008
ENV PORT=3008
ENV HOSTNAME="0.0.0.0"
CMD ["node", "server.js"]
