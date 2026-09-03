FROM node:22-alpine
WORKDIR /app
COPY server/package.json ./server/package.json
RUN cd server && npm install --omit=dev
COPY src ./src
COPY server ./server
ENV HOST=0.0.0.0 PORT=8080
EXPOSE 8080
CMD ["node", "server/index.js"]
