FROM node:20-alpine
WORKDIR /app
# Install rclone for Google Drive backup browser
RUN apk add --no-cache curl unzip && \
    curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
    unzip rclone-current-linux-amd64.zip && \
    cp rclone-*-linux-amd64/rclone /usr/local/bin/ && \
    rm -rf rclone-*
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 8080
CMD ["node", "server.js"]
