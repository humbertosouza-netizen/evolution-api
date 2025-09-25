# ---------- Builder ----------
FROM node:20-alpine AS builder
WORKDIR /evolution

# Toolchain p/ deps nativas e utilitários usados em runtime
RUN apk add --no-cache python3 make g++ bash git openssl tzdata ffmpeg

# Instala somente pelo lockfile
COPY package.json package-lock.json ./
RUN npm ci

# Copia o restante do projeto e compila (tsup -> dist/)
COPY . .
RUN npm run build

# Mantém só deps de produção p/ a imagem final
RUN npm prune --omit=dev

# ---------- Runner ----------
FROM node:20-alpine AS runner
WORKDIR /app
RUN apk add --no-cache tzdata ffmpeg bash openssl

COPY --from=builder /evolution/node_modules ./node_modules
COPY --from=builder /evolution/dist ./dist
COPY --from=builder /evolution/package.json ./package.json

ENV NODE_ENV=production
EXPOSE 8080
# seu "main" aponta para ./dist/main.js
CMD ["node", "dist/main.js"]
