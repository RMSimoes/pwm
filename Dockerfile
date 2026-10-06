# Build da imagem PWM (fork resethub) sem depender do jib/maven local.
# Produz uma imagem com o mesmo layout da imagem oficial pwm/pwm-webapp
# (/app/startup.sh, /app/libs/*onejar*.jar, volume /config, porta 8443),
# para poder substituí-la diretamente num deployment existente.
#
#   docker build -t resethub/pwm-webapp:latest .

ARG BUILD_IMAGE=eclipse-temurin:25-jdk
ARG RUNTIME_IMAGE=eclipse-temurin:26-jre@sha256:6272dd10034adf1177526d8c7c095f7190a170adc66b550006b1b40b17119963

FROM ${BUILD_IMAGE} AS build
WORKDIR /src
COPY . .
RUN --mount=type=cache,target=/root/.m2 \
    ./mvnw --batch-mode --no-transfer-progress \
        -P skip-docker,skip-checkstyle,skip-spotbugs,skip-owasp \
        -DskipTests \
        -pl onejar -am \
        package \
 && mkdir -p /out/libs \
 && find onejar/target -maxdepth 1 -name 'pwm-onejar-*.jar' ! -name '*-sources.jar' ! -name '*-javadoc.jar' \
        -exec cp {} /out/libs/ \; \
 && test "$(ls /out/libs | wc -l)" -eq 1

FROM ${RUNTIME_IMAGE}
COPY docker/src/main/image-files/ /
COPY --from=build /out/libs/ /app/libs/
RUN chmod 755 /app/startup.sh /app/command.sh
EXPOSE 8443
VOLUME /config
ENTRYPOINT ["/app/startup.sh"]
