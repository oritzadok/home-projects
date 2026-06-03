FROM maven:3.8.4-openjdk-17-slim AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package

FROM openjdk:26-slim AS runtime
WORKDIR /app
COPY --from=build /app/target/*.jar ./app.jar
RUN useradd -m appuser
USER appuser
ENTRYPOINT ["java", "-jar", "./app.jar"]
