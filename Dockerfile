# ---------- Builder ----------
FROM node:20-alpine AS builder
WORKDIR /evolution
RUN apk add --no-cache python3 make g++ bash git openssl tzdata ffmpeg

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build
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
CMD ["node", "dist/index.js"]
