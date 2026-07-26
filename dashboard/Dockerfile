FROM node:20-alpine
WORKDIR /app
# Install rclone + docker-cli for Google Drive backup browser and container management
RUN apk add --no-cache curl unzip docker-cli && \
    curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
    unzip rclone-current-linux-amd64.zip && \
    cp rclone-*-linux-amd64/rclone /usr/local/bin/ && \
    rm -rf rclone-*
# Build frontend
COPY frontend/package*.json ./frontend/
RUN cd frontend && npm install
COPY frontend/ ./frontend/
RUN cd frontend && npm run build

RUN mkdir -p /app/userdata
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 8080
CMD ["node", "server.js"]
