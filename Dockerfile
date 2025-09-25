# ---------- Builder ----------
FROM node:20-alpine AS builder
WORKDIR /evolution

# deps para pacotes nativos (se houver)
RUN apk add --no-cache python3 make g++ bash git openssl tzdata ffmpeg

# habilita o corepack (pnpm)
RUN corepack enable

# copie os manifests corretos
COPY package.json pnpm-lock.yaml ./
# se houver .npmrc/.pnpmfile.cjs e tsconfig/tsup, copie também
COPY tsconfig.json tsup.config.ts ./

# instale com lockfile (dev deps incluídas para build)
RUN pnpm install --frozen-lockfile

# agora copie o código
COPY src ./src

# build (ajuste o script se for diferente)
RUN pnpm build

# remova dev deps e mantenha só prod para a imagem final
RUN pnpm prune --prod

# ---------- Runner ----------
FROM node:20-alpine AS runner
WORKDIR /app
RUN apk add --no-cache tzdata ffmpeg bash openssl

# traga só o necessário
COPY --from=builder /evolution/node_modules ./node_modules
COPY --from=builder /evolution/dist ./dist
COPY --from=builder /evolution/package.json ./package.json

ENV NODE_ENV=production
EXPOSE 8080
# ajuste se o entrypoint/dist mudar no seu projeto:
CMD ["node", "dist/index.js"]
