# ----------------------------------------------------
# Stage 1: Build Application
# ----------------------------------------------------
FROM node:22-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache openssl libc6-compat

# Install package dependencies
COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci

# Copy source code and build
COPY tsconfig.json ./
COPY src ./src/
RUN npx prisma generate
RUN npm run build

# ----------------------------------------------------
# Stage 2: Production Runner
# ----------------------------------------------------
FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=5050

# Install runtime dependencies for Prisma
RUN apk add --no-cache openssl libc6-compat

# Copy package definitions and install only production dependencies
COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci --omit=dev && npx prisma generate

# Copy built code from builder stage
COPY --from=builder /app/dist ./dist

# Create uploads directory
RUN mkdir -p uploads/images uploads/videos uploads/files uploads/avatars

# Expose API Port
EXPOSE 5050

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5050/api/health || exit 1

CMD ["node", "dist/server.js"]

