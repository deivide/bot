# syntax=docker/dockerfile:1

FROM oven/bun:1 AS builder

WORKDIR /build

COPY --link scripts scripts
RUN chmod +x ./scripts/start.sh

COPY package.json bun.lock ./

RUN CI=true bun install --production --frozen-lockfile

COPY --link . .

# node:22-alpine3.20 has been frozen at 22.16.0 since 2025-05 and misses the
# 2026-10-21 Node.js security release (CVE-2026-111497 and others).
FROM node:22.23.4-alpine3.24 AS runner
LABEL org.opencontainers.image.source=https://github.com/deivide/bot \
	org.opencontainers.image.description="Discord Tickets (github.com/discord-tickets/bot by eartharoid and contributors), image rebuilt by deivide on a patched Node.js base." \
	org.opencontainers.image.licenses="GPL-3.0-or-later"

RUN apk --no-cache add curl

RUN adduser --disabled-password --home /home/container container
RUN mkdir /app \
	&& chown container:container /app \
	&& chmod -R 777 /app

RUN mkdir -p /home/container/user /home/container/logs \
    && chown -R container:container /home/container

USER container
ENV USER=container \
	HOME=/home/container \
	NODE_ENV=production \
	HTTP_HOST=0.0.0.0 \
	DOCKER=true

WORKDIR /home/container

COPY --from=builder --chown=container:container --chmod=777 /build /app

ENTRYPOINT [ "/app/scripts/start.sh" ]
HEALTHCHECK --interval=15s --timeout=5s --start-period=60s \
	CMD curl -f http://localhost:${HTTP_PORT}/status || exit 1
