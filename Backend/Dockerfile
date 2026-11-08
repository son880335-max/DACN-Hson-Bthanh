FROM node:24-bookworm-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json ./
COPY src ./src
COPY scripts ./scripts
RUN npm run build

FROM node:24-bookworm-slim
ENV NODE_ENV=production HOST=0.0.0.0 PORT=3000
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends fonts-dejavu-core && apt-get clean
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && mkdir -p /app/.local/media && chown -R node:node /app/.local
COPY --from=build /app/dist/src ./dist/src
COPY --from=build /app/dist/scripts/migrate.js ./dist/scripts/migrate.js
COPY migrations ./migrations
USER node
EXPOSE 3000
CMD ["node","dist/src/main.js"]
