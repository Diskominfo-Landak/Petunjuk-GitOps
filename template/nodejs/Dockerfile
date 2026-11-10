# syntax=docker/dockerfile:1

# ---- Tahap 1: pasang dependensi produksi ----
FROM node:20-alpine AS deps
WORKDIR /app

COPY src/package.json src/package-lock.json* ./
RUN if [ -f package-lock.json ]; then \
      npm ci --omit=dev --ignore-scripts; \
    else \
      npm install --omit=dev --no-audit; \
    fi

# ---- Tahap 2: image runtime ----
FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

# Jalankan sebagai non-root user bawaan Alpine Node
USER node

COPY --chown=node:node --from=deps /app/node_modules ./node_modules
COPY --chown=node:node src/ ./

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q --spider http://127.0.0.1:3000/healthz || exit 1

CMD ["node", "server.js"]
