FROM node:18-alpine
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install --production
COPY . .
RUN mkdir -p uploads
EXPOSE 3000
CMD ["npm", "start"]
