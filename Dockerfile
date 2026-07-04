# syntax=docker/dockerfile:1
FROM caddy:2.11.4-builder AS builder

RUN xcaddy build \
    --with github.com/corazawaf/coraza-caddy/v2 \
    --with github.com/mholt/caddy-ratelimit

FROM caddy:2.11.4-alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

RUN addgroup -S caddy && adduser -S caddy -G caddy

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD netstat -an | grep LISTEN | grep -q 80 || exit 1
  
USER caddy