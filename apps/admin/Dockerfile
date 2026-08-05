FROM node:22-alpine AS base

WORKDIR /app

ARG NEXT_PUBLIC_API_URL=https://api.iooeh.com
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .

RUN npm run build

EXPOSE 3000
CMD ["npm", "start"]
