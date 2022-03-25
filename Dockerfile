# Dockerfile
# gets the docker parent image
FROM ruby:3.0.1  

RUN apt-get update && apt-get install -y npm && npm install -g yarn

RUN mkdir -p /var/app/tutorial
COPY ./tutorial/*  /var/app/tutorial/
WORKDIR /var/app/tutorial
RUN bundle install
WORKDIR /var/app/
RUN rails new tutorial1
WORKDIR /var/app/tutorial1
EXPOSE 3000
CMD rails s -b 0.0.0.0


