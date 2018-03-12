FROM node:carbon

ADD . ./server
WORKDIR /server

RUN npm install 

CMD ["npm", "run", "start-production"]