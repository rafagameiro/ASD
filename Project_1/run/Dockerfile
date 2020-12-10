FROM openjdk:14-alpine

RUN apk add --no-cache \
                bind-tools \
                iproute2 \
                nload

WORKDIR code
ADD docker/* ./
ADD config/log4j2.xml ./config/
ADD config/config.properties ./config/
ADD target/asdProj.jar .

ENTRYPOINT ["./setupTc.sh"]
