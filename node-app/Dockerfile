FROM node:20-alpine

RUN mkdir -p /home/app

COPY ./app /home/app

WORKDIR /home/app

RUN npm install

ENV NODE_ENVIRONMENT=docker-development

CMD ["npm", "run" , "start"]
