# syntax=docker/dockerfile:1

FROM eclipse-temurin:8-jdk-jammy AS builder

ARG DEBIAN_FRONTEND=noninteractive
ARG BIOPET_VERSION=v0.9.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    maven \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN git clone --branch "${BIOPET_VERSION}" --depth 1 --recurse-submodules https://github.com/biopet/biopet.git

WORKDIR /opt/biopet
RUN mvn -DskipTests -pl biopet-package -am package

RUN set -eux; \
    JAR_PATH="$(find biopet-package/target -maxdepth 1 -type f -name 'Biopet-*.jar' ! -name 'original-*' | head -n 1)"; \
    test -n "${JAR_PATH}"; \
    mkdir -p /opt/build; \
    cp "${JAR_PATH}" /opt/build/Biopet.jar

FROM eclipse-temurin:8-jre-jammy

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    python3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/build/Biopet.jar /opt/biopet/Biopet.jar

RUN printf '#!/usr/bin/env bash\nexec java -jar /opt/biopet/Biopet.jar "$@"\n' > /usr/local/bin/biopet \
    && chmod +x /usr/local/bin/biopet

WORKDIR /data
ENTRYPOINT ["biopet"]
