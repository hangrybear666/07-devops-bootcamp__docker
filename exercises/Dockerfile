FROM gradle:8.5.0-jdk17-focal

RUN mkdir -p /home/java-app/src

EXPOSE 8080

ENV DB_USER=mysql-user \
    DB_SERVER=mysqldb \
    DB_NAME=team-member-projects

COPY ./src /home/java-app/src
COPY build.gradle /home/java-app
COPY settings.gradle /home/java-app

WORKDIR /home/java-app

RUN gradle clean build 

WORKDIR /home/java-app/build/libs

CMD java -jar docker-exercises-project-1.0-SNAPSHOT.jar
