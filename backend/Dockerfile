FROM node:22-bookworm-slim AS dependencies

WORKDIR /app
ENV DATABASE_URL=mysql://build:build@127.0.0.1:3306/cultiva

RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 make g++ \
  && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
COPY prisma ./prisma
COPY prisma.config.ts ./
RUN npm ci

FROM dependencies AS build

COPY . .
RUN npm run build
RUN npm prune --omit=dev --ignore-scripts

FROM dependencies AS migrations
USER node
CMD ["npx", "prisma", "migrate", "deploy"]

FROM node:22-bookworm-slim AS runtime

WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000

COPY --from=build --chown=node:node /app/node_modules ./node_modules
COPY --from=build --chown=node:node /app/dist ./dist

RUN mkdir -p /app/storage_uploads && chown node:node /app/storage_uploads

USER node
EXPOSE 3000
CMD ["node", "dist/main.js"]
