# syntax=docker/dockerfile:1.7

FROM node:22-alpine AS dependencies

WORKDIR /usr/local/app

COPY package*.json ./

RUN npm ci --omit=dev \
    && npm cache clean --force


FROM node:22-alpine AS runtime

ENV NODE_ENV=production

WORKDIR /usr/local/app

RUN apk add --no-cache dumb-init \
    && addgroup -S appgroup \
    && adduser -S -G appgroup -u 10001 appuser \
    && mkdir -p /etc/todos \
    && chown -R appuser:appgroup /usr/local/app /etc/todos

COPY --from=dependencies \
    --chown=appuser:appgroup \
    /usr/local/app/node_modules \
    ./node_modules

COPY --chown=appuser:appgroup . .

USER 10001:10001

EXPOSE 3000

HEALTHCHECK \
    --interval=30s \
    --timeout=3s \
    --start-period=10s \
    --retries=3 \
    CMD wget -qO- http://127.0.0.1:3000/ >/dev/null || exit 1

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["node", "src/index.js"]
