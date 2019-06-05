FROM openjdk:8-jdk-alpine
LABEL maintainer="wanyihang@100tal.com"
ARG JAR_FILE
ARG WORK_PATH="/opt/demo"
ENV JAVA_OPTS="" \
    JAR_FILE=${JAR_FILE}

RUN apk update && apk add ca-certificates && \
    apk add tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone
COPY target/$JAR_FILE $WORK_PATH/
WORKDIR $WORK_PATH
ENTRYPOINT exec java $JAVA_OPTS -jar $JAR_FILE
