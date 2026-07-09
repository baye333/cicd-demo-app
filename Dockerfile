# ============================================
# STAGE 1 : Build - installation des dépendances
# ============================================
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci --omit=dev

COPY . .

# ============================================
# STAGE 2 : Production - image finale allégée
# ============================================
FROM node:20-alpine AS production

# Créer un utilisateur non-root pour la sécurité
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeapp -u 1001 -G nodejs

WORKDIR /app

# Copier uniquement ce qui est nécessaire depuis le stage builder
COPY --from=builder --chown=nodeapp:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodeapp:nodejs /app/app.js ./app.js
COPY --from=builder --chown=nodeapp:nodejs /app/package.json ./package.json

USER nodeapp

EXPOSE 3000

ENV PORT=3000
ENV APP_VERSION=1.0.0

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"

CMD ["node", "app.js"]