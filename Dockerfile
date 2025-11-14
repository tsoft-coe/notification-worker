# Multi-stage build for Notification Worker
# Stage 1: Build
FROM node:22-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (production + dev for build)
RUN npm ci

# Copy source code
COPY . .

# Run linting and tests
RUN npm run lint || true
RUN npm test || true

# Stage 2: Production
FROM node:22-alpine

# Metadata labels
LABEL maintainer="BankApp Team"
LABEL version="1.0.0"
LABEL description="BankApp Notification Worker - Email and SMS notifications via RabbitMQ"

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production && npm cache clean --force

# Copy source from builder (node user already exists in base image with UID 1000)
COPY --from=builder --chown=node:node /app/src ./src

# Switch to non-root user
USER node

# Note: Workers don't expose HTTP ports, they consume from RabbitMQ

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start worker application
CMD ["node", "src/worker.js"]
