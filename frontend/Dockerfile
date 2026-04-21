FROM node:20-alpine
WORKDIR /app

# Install dependencies
COPY package.json package-lock.json* ./
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

# Copy source code (will be overridden by volume mount in docker-compose)
COPY . .

EXPOSE 3000
ENV PORT 3000

# Use development server by default (live reload with volume mount)
# For production: NODE_ENV=production npm run start
CMD ["npm", "run", "dev"]
