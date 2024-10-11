# 빌드 단계
FROM node:18 as build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# 실행 단계
FROM node:18-slim

WORKDIR /app

COPY --from=build /app/package*.json ./
COPY --from=build /app/build ./build

RUN npm install --production

EXPOSE 3000

CMD ["node", "build"]