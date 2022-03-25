# Dockerfile
# gets the docker parent image
FROM ruby:3.0.1  

RUN apt-get update && apt-get install -y npm && npm install -g yarn

RUN mkdir -p /var/app
COPY ./tutorial/*  /var/app/
WORKDIR /var/app
CMD rails new tutorial
WORKDIR /var/app/tutorial
RUN bundle install
EXPOSE 3000
CMD rails s -b 0.0.0.0


