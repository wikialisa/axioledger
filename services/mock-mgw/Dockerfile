FROM node:26-alpine
WORKDIR /app
RUN npm install -g pnpm

COPY services/mock-mgw/package.json ./package.json
RUN pnpm install

COPY services/mock-mgw/src ./src
COPY services/mock-mgw/tsconfig.json ./tsconfig.json

EXPOSE 9003
CMD ["pnpm", "start"]
