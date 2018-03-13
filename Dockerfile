FROM node:carbon

ADD . ./server
WORKDIR /server

RUN npm install
RUN chmod +x ./wait-for-it.sh

CMD ["npm", "run", "start-production"]