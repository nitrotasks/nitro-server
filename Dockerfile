FROM node:10

ADD . ./server
WORKDIR /server

RUN npm ci
RUN chmod +x ./wait-for-it.sh

CMD ["npm", "run", "start-production"]