# Stage 0: Base stage with Node.js
FROM node:20 AS base

WORKDIR /app

COPY package*.json /app/

RUN npm install

COPY ./ /app/

# Stage 1: Development stage for testing
FROM base AS development

ENV NODE_ENV=development

CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]

# Stage 2: Build stage for production
FROM base AS build-stage

ARG VITE_API_URL=${VITE_API_URL}

RUN npm run build

# Stage 3: Production stage with Traefik
# Traefik will handle the routing and serving
